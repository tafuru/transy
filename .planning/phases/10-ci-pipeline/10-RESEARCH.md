# Phase 10: CI Pipeline - Research

**Researched:** 2026-03-27
**Domain:** GitHub Actions CI for macOS/Swift/XcodeGen project
**Confidence:** HIGH

## Summary

Phase 10 delivers a GitHub Actions CI workflow that validates every PR targeting `main` with SwiftLint, SwiftFormat, xcodebuild build, and xcodebuild test. All four tools except XcodeGen are pre-installed on the `macos-15` runner. The phase also requires creating `.swiftlint.yml` and `.swiftformat` configuration files and fixing 4 existing source lines that exceed the 150-character line limit.

The project is small (23 source files, ~1,360 LOC; 14 test files, ~900 LOC) so clean builds are fast (~1-2 min) and no caching is needed. The existing research at `.planning/research/ci-pipeline.md` provides verified workflow YAML templates and tool configurations that serve as the foundation. This research validates, refines, and fills gaps in that document.

**Primary recommendation:** Implement exactly two parallel GitHub Actions jobs (`lint` and `build-and-test`) with the tool versions pre-installed on `macos-15`. Fix the 4 lines exceeding 150 chars. No caching, no Xcode version pinning.

<user_constraints>

## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Strict SwiftLint ruleset — default rules plus opt-in rules (`empty_count`, `first_where`, `modifier_order`, etc.). Line length set to 150.
- **D-02:** SwiftUI-specific rules disabled: `type_body_length`, `function_body_length` (SwiftUI views naturally produce longer bodies).
- **D-03:** All existing code checked — no grandfathered exclusions. Fix all warnings in the initial PR.
- **D-04:** Indent style: 4 spaces (matches `project.yml` `indentWidth: 4`).
- **D-05:** Disable SwiftFormat rules that conflict with SwiftLint: `redundantSelf`, `trailingCommas`, and any other overlapping rules.
- **D-06:** Apply to all existing code — no file exclusions.
- **D-07:** Trigger: `on: pull_request` targeting `main` only. No push triggers (branch protection already blocks direct pushes).
- **D-08:** Two parallel jobs: `lint` (SwiftLint + SwiftFormat) and `build-and-test` (xcodegen + xcodebuild build + test).
- **D-09:** All jobs are required status checks — lint failures block merge, same as build/test failures.
- **D-10:** Runner: `macos-15` (SwiftLint, SwiftFormat, xcbeautify pre-installed; only XcodeGen needs `brew install`).

### Agent's Discretion

- Specific opt-in SwiftLint rules beyond the ones mentioned — agent may add reasonable rules that improve code quality for Swift 6 / SwiftUI
- SwiftFormat rules to disable beyond `redundantSelf` and `trailingCommas` — agent should resolve any conflicts found during testing
- Whether to use `--strict` flag on SwiftLint (treats warnings as errors)

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope.

</user_constraints>

<phase_requirements>

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CI-01 | PR to main triggers SwiftLint check on project sources | SwiftLint 0.63.2 pre-installed on macos-15; `--reporter github-actions-logging` produces inline PR annotations; `.swiftlint.yml` config needed at repo root |
| CI-02 | PR to main triggers SwiftFormat check on project sources | SwiftFormat 0.59.1 pre-installed on macos-15; `--lint` mode returns non-zero on violations; `.swiftformat` config needed at repo root |
| CI-03 | PR to main triggers xcodebuild build for macOS | xcodebuild with `CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO` avoids signing errors; XcodeGen must be installed first; `fetch-depth: 0` needed for git-tag version script |
| CI-04 | PR to main triggers xcodebuild test for macOS | Swift Testing framework works with standard `xcodebuild test` on Xcode 16+; xcbeautify formats output with GitHub Actions annotations |

</phase_requirements>

## Project Constraints (from copilot-instructions.md)

- **Development rules** live in `.github/DEVELOPMENT.md` — all workflow follows that file
- **Branch naming:** `phase/{phase}-{slug}` (e.g., `phase/10-ci-pipeline`)
- **Commits:** Conventional Commits format with `Co-authored-by` trailer
- **PRs:** Squash-merge, include `Closes #15` for phase issue
- **Language:** Code, commits, PRs in English; chat in Japanese

## Standard Stack

### Core (Pre-installed on `macos-15` runner)

| Tool | Version | Purpose | Pre-installed |
|------|---------|---------|---------------|
| SwiftLint | 0.63.2 | Lint Swift sources for style/correctness | ✅ Yes |
| SwiftFormat | 0.59.1 | Check formatting consistency | ✅ Yes |
| xcbeautify | 3.1.4 | Format xcodebuild output as GitHub annotations | ✅ Yes |
| Xcode | 16.4 (default) | Build & test (Swift 6.0 compatible) | ✅ Yes |
| actions/checkout | v4 | Clone repository | GitHub Action |
| actions/cache | v4 | Cache dependencies (not needed now) | GitHub Action |

### Must Install

| Tool | Install Command | Time | Purpose |
|------|----------------|------|---------|
| XcodeGen | `brew install xcodegen` | ~15s with HOMEBREW_NO_AUTO_UPDATE=1 | Generate .xcodeproj from project.yml |

### Not Needed

| Tool | Why Not |
|------|---------|
| SPM cache | No Package.resolved — zero SPM dependencies |
| DerivedData cache | Small project (~1,360 LOC), clean build < 2 min; out of scope per REQUIREMENTS.md |
| Xcode version pinning | Default Xcode 16.4 is backward-compatible with Swift 6.0 and macOS 15.0 target |
| Mint | Only one tool (XcodeGen) to install — Homebrew is simpler |

**Confidence:** HIGH — runner image contents verified from actions/runner-images macos-15 README.

## Architecture Patterns

### File Structure

```
.
├── .github/
│   └── workflows/
│       └── ci.yml              # CI workflow (NEW)
├── .swiftlint.yml              # SwiftLint config (NEW)
├── .swiftformat                # SwiftFormat config (NEW)
├── project.yml                 # XcodeGen project definition (EXISTS)
├── Transy/                     # 23 source files (EXISTS)
├── TransyTests/                # 14 test files (EXISTS)
└── TransyUITests/              # 1 UI test file (EXISTS)
```

### Pattern 1: Two Parallel Jobs

**What:** `lint` job and `build-and-test` job run in parallel, not sequentially.
**Why:** Linting doesn't need XcodeGen or xcodebuild. Running in parallel saves time and gives faster feedback on style violations. A lint failure shouldn't wait for a build to complete.

```
PR opened → ┬─ lint job ──────── (SwiftLint → SwiftFormat) → pass/fail
            └─ build-and-test ── (XcodeGen → build → test) → pass/fail
```

### Pattern 2: Concurrency Groups with Cancel-in-Progress

**What:** `concurrency.group: ci-${{ github.ref }}` with `cancel-in-progress: true`.
**Why:** macOS runners cost 10x Linux runners. When a developer pushes a new commit to a PR branch, the stale run is cancelled immediately. This is required by the success criteria.

### Pattern 3: Code Signing Disabled

**What:** Always pass `CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO` to xcodebuild.
**Why:** CI runners have no signing certificates. Without these flags, xcodebuild fails with cryptic signing errors.

### Pattern 4: Full Git History for Version Script

**What:** `actions/checkout@v4` with `fetch-depth: 0`.
**Why:** The post-build script in `project.yml` runs `git describe --tags --abbrev=0` to set `CFBundleShortVersionString`. With the default shallow clone (`fetch-depth: 1`), this command fails because tags aren't fetched. Full history is required. The repo has tags v0.1.0, v0.2.0, v0.3.0.

### Anti-Patterns to Avoid

- **Running lint inside build-and-test:** Wastes time — lint doesn't need XcodeGen/xcodebuild.
- **Using `push` trigger alongside `pull_request`:** Branch protection already blocks direct pushes to main. Adding `push` trigger causes duplicate runs when a PR is pushed.
- **Caching DerivedData with XcodeGen:** XcodeGen regenerates the .xcodeproj each run, frequently invalidating DerivedData cache. More harm than help for small projects.
- **Pinning Xcode 16.0:** The default 16.4 is backward-compatible with Swift 6.0. Pinning prevents catching deprecation warnings early.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Inline PR annotations | Custom `::error file=...` workflow commands | SwiftLint `--reporter github-actions-logging` + xcbeautify `--renderer github-actions` | Built-in, maintained, handles all edge cases |
| Build output formatting | Raw xcodebuild output parsing | `xcbeautify --renderer github-actions` | xcbeautify is pre-installed and formats errors/warnings as GitHub annotations |
| XcodeGen binary caching | Custom download + cache steps | `brew install xcodegen` with `HOMEBREW_NO_AUTO_UPDATE=1` | 15s install is negligible; caching adds complexity for no gain |
| SwiftLint/SwiftFormat install | Homebrew install steps | Pre-installed on runner | Already available on macos-15 |

## Existing Code Compliance Issues

**4 lines exceed the 150-character line limit (D-01).** Per D-03, all must be fixed:

| File | Line | Chars | Content | Fix Strategy |
|------|------|-------|---------|--------------|
| `Transy/Settings/TranslationModelGuidance.swift` | 53 | 153 | Long closure type signature | Break across lines |
| `Transy/Settings/GeneralSettingsView.swift` | 58 | 155 | Long `Text()` string literal | Break string or extract to constant |
| `Transy/Settings/GeneralSettingsView.swift` | 79 | 166 | Long `Text()` with interpolation | Break string or extract to constant |
| `Transy/Permissions/GuidanceView.swift` | 9 | 210 | Long `Text()` string literal | Break string or extract to constant |

**Note on `self.` usage:** The codebase uses `self.` in initializers (e.g., `self.id = language.minimalIdentifier`). This is valid Swift. SwiftFormat's `redundantSelf` rule would remove these — correctly disabled per D-05. Additional SwiftFormat rule `redundantInit` should also be evaluated for conflicts.

**Confidence:** HIGH — verified by scanning all .swift files with `awk 'length > 150'`.

## Common Pitfalls

### Pitfall 1: Shallow Clone Breaks Version Script
**What goes wrong:** `git describe --tags --abbrev=0` fails with `fatal: No names found, cannot describe anything` on shallow clones.
**Why it happens:** `actions/checkout@v4` defaults to `fetch-depth: 1`. Tags are not included.
**How to avoid:** Always use `fetch-depth: 0` in the `build-and-test` job checkout step. The `lint` job does NOT need full history.
**Warning signs:** Build step succeeds but version shows "0.0.0" or the post-build script fails silently.

### Pitfall 2: Code Signing Errors on CI
**What goes wrong:** xcodebuild fails with `No signing certificate "Mac Development" found`.
**Why it happens:** CI runners have no developer certificates installed.
**How to avoid:** Pass `CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO` to every xcodebuild invocation.
**Warning signs:** Build fails immediately after linking with signing-related errors.

### Pitfall 3: SwiftLint/SwiftFormat Config Conflicts
**What goes wrong:** SwiftLint and SwiftFormat disagree on formatting, causing an infinite fix-lint loop.
**Why it happens:** Both tools have overlapping rules (e.g., `redundantSelf`, `trailingCommas`). If enabled in both, one tool "fixes" what the other reports.
**How to avoid:** Disable overlapping SwiftFormat rules per D-05: `redundantSelf`, `trailingCommas`. Test both tools together before committing configs.
**Warning signs:** Running `swiftformat .` then `swiftlint lint` produces new violations.

### Pitfall 4: xcbeautify Masking Exit Codes
**What goes wrong:** xcodebuild fails but the CI step shows green.
**Why it happens:** Piping output can mask the exit code of the first command.
**How to avoid:** GitHub Actions bash uses `set -eo pipefail` by default, so this is handled automatically. Do NOT override the shell with `set +o pipefail`.
**Warning signs:** Build has compilation errors in the log but the step shows success.

### Pitfall 5: SwiftFormat `--reporter` Flag Availability
**What goes wrong:** `swiftformat --lint . --reporter github-actions-log` fails with "unknown option".
**Why it happens:** The `--reporter` flag may not exist in all SwiftFormat versions. Need runtime verification.
**How to avoid:** Test the exact command on the runner. If `--reporter` is unavailable, fall back to plain `swiftformat --lint .` (which still fails on violations but without inline annotations). SwiftLint already provides inline annotations via `--reporter github-actions-logging`.
**Warning signs:** "Unknown option" error in CI output.

### Pitfall 6: Homebrew Auto-Update Delay
**What goes wrong:** `brew install xcodegen` takes 2+ minutes instead of 15 seconds.
**Why it happens:** Homebrew auto-updates itself before every install by default.
**How to avoid:** Set `HOMEBREW_NO_AUTO_UPDATE: 1` and `HOMEBREW_NO_INSTALL_CLEANUP: 1` as environment variables.
**Warning signs:** CI logs show "Updating Homebrew..." taking 60+ seconds.

## Code Examples

### CI Workflow YAML (`.github/workflows/ci.yml`)

Source: `.planning/research/ci-pipeline.md` (adapted per locked decisions)

```yaml
# .github/workflows/ci.yml
name: CI

on:
  pull_request:
    branches: [main]

concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true

env:
  HOMEBREW_NO_AUTO_UPDATE: 1
  HOMEBREW_NO_INSTALL_CLEANUP: 1

jobs:
  lint:
    name: Lint
    runs-on: macos-15
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: SwiftLint
        run: swiftlint lint --strict --reporter github-actions-logging

      - name: SwiftFormat
        run: swiftformat --lint .

  build-and-test:
    name: Build & Test
    runs-on: macos-15
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Install XcodeGen
        run: brew install xcodegen

      - name: Generate Xcode project
        run: xcodegen generate

      - name: Build
        run: |
          xcodebuild build \
            -scheme Transy \
            -destination 'platform=macOS' \
            -configuration Debug \
            CODE_SIGN_IDENTITY="-" \
            CODE_SIGNING_REQUIRED=NO \
            CODE_SIGNING_ALLOWED=NO \
            | xcbeautify --renderer github-actions

      - name: Test
        run: |
          xcodebuild test \
            -scheme Transy \
            -destination 'platform=macOS' \
            CODE_SIGN_IDENTITY="-" \
            CODE_SIGNING_REQUIRED=NO \
            CODE_SIGNING_ALLOWED=NO \
            | xcbeautify --renderer github-actions
```

**Key design notes:**
- `on: pull_request` only (not `push`) per D-07 — branch protection handles direct push blocking
- `lint` job has NO `fetch-depth: 0` — it doesn't need git history, saving time
- `build-and-test` has `fetch-depth: 0` — required for `git describe --tags` in version script
- Build and Test are separate steps (not combined) for clear failure attribution
- `--strict` on SwiftLint per agent discretion — treats warnings as errors for CI rigor

### SwiftLint Configuration (`.swiftlint.yml`)

Source: `.planning/research/ci-pipeline.md` (adapted per D-01, D-02, D-03)

```yaml
# .swiftlint.yml

included:
  - Transy
  - TransyTests
  - TransyUITests

excluded:
  - Transy.xcodeproj

disabled_rules:
  - type_body_length          # D-02: SwiftUI views are naturally long
  - function_body_length      # D-02: SwiftUI body property can be lengthy

opt_in_rules:
  - empty_count               # Prefer .isEmpty over .count == 0
  - empty_string              # Prefer .isEmpty over == ""
  - first_where               # Prefer .first(where:) over .filter{}.first
  - last_where                # Prefer .last(where:) over .filter{}.last
  - sorted_first_last         # Use .min()/.max() over .sorted().first/.last
  - contains_over_filter_count
  - contains_over_filter_is_empty
  - contains_over_first_not_nil
  - contains_over_range_nil_comparison
  - flatmap_over_map_reduce
  - modifier_order            # Consistent modifier order (good for SwiftUI)
  - closure_spacing           # Consistent closure spacing
  - overridden_super_call
  - discouraged_optional_boolean
  - prefer_self_in_static_references
  - prefer_self_type_over_type_of_self
  - unavailable_function
  - unowned_variable_capture
  - vertical_whitespace_closing_braces
  - private_action
  - private_outlet

line_length:
  warning: 150
  error: 200
  ignores_comments: true
  ignores_urls: true

identifier_name:
  min_length:
    warning: 2
    error: 1
  excluded:
    - id
    - x
    - y
    - i

nesting:
  type_level:
    warning: 3

reporter: xcode
```

### SwiftFormat Configuration (`.swiftformat`)

Source: `.planning/research/ci-pipeline.md` (adapted per D-04, D-05, D-06)

```
# .swiftformat

--swiftversion 6.0
--indent 4
--indentcase false
--maxwidth 150
--semicolons never
--commas always
--stripunusedargs closure-only
--self init-only
--header strip
--wrapcollections before-first
--wraparguments before-first
--wrapparameters before-first

# Exclude non-source directories
--exclude Transy.xcodeproj,.build,DerivedData

# Disable rules that conflict with SwiftLint (D-05)
--disable redundantSelf
--disable trailingCommas

# Disable potentially aggressive rules
--disable acronyms
--disable blankLineAfterSwitchCase
--disable wrapSwitchCases
```

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Swift Testing (via Xcode 16+) |
| Config file | None (built into Xcode test runner) |
| Quick run command | `xcodebuild test -scheme Transy -destination 'platform=macOS' CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO 2>&1 \| head -50` |
| Full suite command | `xcodebuild test -scheme Transy -destination 'platform=macOS' CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CI-01 | SwiftLint reports violations on PR diff | smoke | `swiftlint lint --strict` (local) | N/A — validated by running tool locally then verifying CI output on PR |
| CI-02 | SwiftFormat reports violations on PR diff | smoke | `swiftformat --lint .` (local) | N/A — validated by running tool locally then verifying CI output on PR |
| CI-03 | xcodebuild build catches compilation errors | smoke | `xcodegen generate && xcodebuild build -scheme Transy -destination 'platform=macOS' CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO` | N/A — validated by CI run |
| CI-04 | xcodebuild test catches test failures | smoke | `xcodegen generate && xcodebuild test -scheme Transy -destination 'platform=macOS' CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO` | N/A — validated by CI run |

**Note:** CI pipeline validation is inherently integration-level. The real test is opening a PR and observing that all checks pass. Local validation can verify configs are syntactically correct and existing code is compliant.

### Sampling Rate

- **Per task commit:** Run `swiftlint lint --strict` and `swiftformat --lint .` locally after creating/editing configs
- **Per wave merge:** Push PR, verify all CI checks pass
- **Phase gate:** PR with all 4 checks passing (lint, swiftformat, build, test)

### Wave 0 Gaps

- [ ] `.github/workflows/` directory does not exist — must create
- [ ] `.swiftlint.yml` does not exist — must create
- [ ] `.swiftformat` does not exist — must create
- [ ] 4 source lines exceed 150-char limit — must fix before lint passes

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| SwiftLint via Homebrew on CI | Pre-installed on macos-15 runner | 2024 runner image updates | No install step needed |
| XCTest for Swift unit tests | Swift Testing framework (`@Test`, `#expect`) | Xcode 16 / Swift 5.10+ | `xcodebuild test` discovers Swift Testing tests automatically |
| `macos-13` / `macos-14` runners | `macos-15` runner | 2024-2025 | macos-13 deprecated, macos-14 deprecation started July 2025 |
| Manual xcodebuild output parsing | `xcbeautify --renderer github-actions` | xcbeautify 2.0+ | Automatic GitHub annotations for errors/warnings |

## Open Questions

1. **SwiftFormat `--reporter github-actions-log` flag**
   - What we know: Existing research states this flag works with SwiftFormat 0.59.1. SwiftFormat added `--reporter` around version 0.54+.
   - What's unclear: Cannot verify locally (SwiftFormat not installed). The pre-installed version on macos-15 (0.59.1) should support it.
   - Recommendation: Try `swiftformat --lint . --reporter github-actions-log` first in the workflow. If it fails, fall back to plain `swiftformat --lint .` which still fails on violations but without inline annotations. SwiftLint already provides inline annotations for style issues, so this is a nice-to-have.

2. **Additional SwiftFormat rule conflicts**
   - What we know: `redundantSelf` and `trailingCommas` are known conflicts (D-05).
   - What's unclear: There may be other SwiftFormat rules that produce output conflicting with SwiftLint rules when both are enabled.
   - Recommendation: After creating both configs, run SwiftFormat then SwiftLint on the codebase. If new violations appear that weren't there before SwiftFormat ran, identify and disable the conflicting SwiftFormat rule.

3. **Required status checks setup**
   - What we know: D-09 says all jobs are required status checks. GitHub branch protection ruleset ID 14329617 exists.
   - What's unclear: Whether to configure required status checks via GitHub API in the same PR or separately.
   - Recommendation: Add status checks via `gh api` after the workflow is verified working on the first PR. This is a post-merge configuration step — the check names (`Lint` and `Build & Test`) must exist in GitHub's check history before they can be marked required.

## Environment Availability

> This phase runs on GitHub Actions (macos-15 runner), not locally. Local environment is used for config validation only.

| Dependency | Required By | Available Locally | On macos-15 Runner | Fallback |
|------------|------------|-------------------|-------------------|----------|
| SwiftLint | CI-01 | ✗ | ✓ (0.63.2) | Install via Homebrew for local testing |
| SwiftFormat | CI-02 | ✗ | ✓ (0.59.1) | Install via Homebrew for local testing |
| xcodebuild | CI-03, CI-04 | ✓ (Xcode installed) | ✓ (Xcode 16.4) | — |
| XcodeGen | CI-03, CI-04 | Unknown | ✗ (must install) | `brew install xcodegen` |
| xcbeautify | CI-03, CI-04 | Unknown | ✓ (3.1.4) | Raw xcodebuild output (less readable) |
| Git tags | Version script | ✓ (v0.1.0, v0.2.0, v0.3.0) | ✓ (with fetch-depth: 0) | — |
| `.github/workflows/` dir | CI workflow | ✗ (doesn't exist) | N/A | Must create |

**Missing locally (not blocking CI):**
- SwiftLint and SwiftFormat not installed locally — can validate by running on CI. Optional: install locally for pre-commit testing.

## Sources

### Primary (HIGH confidence)
- `.planning/research/ci-pipeline.md` — Complete workflow YAML, runner tool versions, XcodeGen install strategy
- `project.yml` — XcodeGen project definition (targets, settings, post-build script)
- `actions/runner-images` macos-15 README — Pre-installed tool versions, Xcode versions
- `.planning/phases/10-ci-pipeline/10-CONTEXT.md` — All locked decisions D-01 through D-10
- Codebase scan (`find`, `awk`) — 4 lines exceeding 150 chars identified, `self.` usage patterns confirmed

### Secondary (MEDIUM confidence)
- SwiftLint GitHub README — `--reporter github-actions-logging` flag, opt-in rules list
- SwiftFormat GitHub README — `--lint` mode, config file format, `--self init-only` option
- GitHub Actions docs — Default shell options (`set -eo pipefail`), concurrency groups

### Tertiary (LOW confidence)
- SwiftFormat `--reporter github-actions-log` flag — described in existing research, unverified locally. Needs runtime validation on CI.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — tool versions verified from runner-images docs, project structure scanned
- Architecture: HIGH — workflow structure follows GitHub Actions best practices, validated against locked decisions
- Pitfalls: HIGH — each pitfall identified from concrete project characteristics (version script, code signing, long lines)
- Validation: MEDIUM — CI validation is inherently integration-level; local smoke tests are limited

**Research date:** 2026-03-27
**Valid until:** 2026-04-27 (stable — GitHub Actions and tool versions change slowly)

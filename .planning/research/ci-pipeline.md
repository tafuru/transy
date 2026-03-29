# CI Pipeline Research: GitHub Actions for Transy

**Project:** Transy (macOS menu-bar translator)
**Researched:** 2025-07-18
**Overall confidence:** HIGH

---

## Overview

Transy needs a CI pipeline that validates PRs by generating the Xcode project from `project.yml`, building for macOS, running Swift Testing unit tests, and enforcing code style with SwiftLint and SwiftFormat. All tools except XcodeGen are pre-installed on GitHub Actions macOS runners, making the setup straightforward.

---

## 1. GitHub Actions macOS Runners

### Available Runners (verified from actions/runner-images repo)

| Runner | OS Version | Default Xcode | All Xcode Versions | Notes |
|--------|-----------|---------------|---------------------|-------|
| `macos-15` | macOS 15.7.4 (Sequoia) | **16.4** | 16.0, 16.1, 16.2, 16.3, **16.4** | ✅ **Use this** |
| `macos-14` | macOS 14.8.4 (Sonoma) | 15.4 | 15.0.1, 15.1, 15.2, 15.3, 15.4, 16.1, 16.2 | ⚠️ Deprecation starts July 6, 2025 |
| `macos-13` | — | — | — | Already deprecated |

**Recommendation:** Use `macos-15`. It matches Transy's `deploymentTarget: "15.0"` (macOS Sequoia), has Xcode 16.0+ (required for Swift 6.0), and won't be deprecated anytime soon.

**Confidence:** HIGH — verified from official runner-images README on GitHub.

### Pre-installed Tools on `macos-15` (no Homebrew install needed)

| Tool | Version | Pre-installed? |
|------|---------|----------------|
| SwiftLint | 0.63.2 | ✅ Yes |
| SwiftFormat | 0.59.1 | ✅ Yes |
| xcbeautify | 3.1.4 | ✅ Yes |
| GitHub CLI (`gh`) | 2.87.3 | ✅ Yes |
| Xcode 16.0 | 16A242d | ✅ Yes |
| Xcode 16.4 (default) | 16F6 | ✅ Yes |
| XcodeGen | — | ❌ **Must install** |

### Xcode Version Selection

Transy's `project.yml` specifies `xcodeVersion: "16.0"` and `SWIFT_VERSION: 6.0`. The default Xcode on `macos-15` is 16.4, which is fully backward-compatible with Swift 6.0 code. **Use the default Xcode 16.4** — no `xcode-select` needed unless you want exact version pinning.

If you want to pin to Xcode 16.0 specifically:

```yaml
- name: Select Xcode 16.0
  run: sudo xcode-select -s /Applications/Xcode_16.app/Contents/Developer
```

**Recommendation:** Don't pin. Xcode 16.4 on `macos-15` works fine with Swift 6.0 and macOS 15.0 deployment target. Testing against the latest Xcode catches deprecation warnings early.

---

## 2. Installing XcodeGen on CI

XcodeGen is the only tool that needs Homebrew installation. Options:

### Option A: Homebrew install (simple, recommended)

```yaml
- name: Install XcodeGen
  run: brew install xcodegen
```

**Pros:** Simple, always latest stable version.
**Cons:** ~15-30 seconds install time. Homebrew updates can add overhead.

### Option B: Direct binary download (faster)

```yaml
- name: Install XcodeGen
  run: |
    XCODEGEN_VERSION="2.42.0"
    curl -sL "https://github.com/yonaskolb/XcodeGen/releases/download/${XCODEGEN_VERSION}/xcodegen.zip" -o xcodegen.zip
    unzip -q xcodegen.zip
    sudo mv xcodegen /usr/local/bin/xcodegen
```

**Pros:** Faster (~5 seconds), pinned version.
**Cons:** Must manually update version. May break if release format changes.

### Option C: Mint (overkill for one tool)

```yaml
- name: Install Mint and XcodeGen
  run: |
    brew install mint
    mint install yonaskolb/XcodeGen
```

**Recommendation:** Use **Option A** (Homebrew). The 15-30 second overhead is negligible for a CI job that takes minutes. Simplicity wins. Add `HOMEBREW_NO_AUTO_UPDATE=1` to skip Homebrew's self-update and save time.

---

## 3. Caching Strategies

### 3a. SPM Package Cache

SPM packages are resolved during `xcodebuild` and cached in DerivedData. Cache the SPM cache directory:

```yaml
- name: Cache SPM packages
  uses: actions/cache@v4
  with:
    path: |
      ~/Library/Caches/org.swift.swiftpm
      ~/Library/org.swift.swiftpm
    key: spm-${{ runner.os }}-${{ hashFiles('**/Package.resolved') }}
    restore-keys: |
      spm-${{ runner.os }}-
```

**Note:** Transy currently uses no SPM packages (only `ServiceManagement.framework` SDK dependency), so this is not needed yet but should be added when SPM dependencies arrive.

### 3b. Homebrew Cache (for XcodeGen)

```yaml
- name: Cache Homebrew
  uses: actions/cache@v4
  with:
    path: |
      ~/Library/Caches/Homebrew
      /usr/local/Cellar/xcodegen
    key: brew-xcodegen-${{ runner.os }}
```

**Recommendation:** Skip Homebrew caching for now. XcodeGen installs in ~15 seconds with `HOMEBREW_NO_AUTO_UPDATE=1`. Caching adds complexity for marginal gain. Revisit if more Homebrew dependencies are added.

### 3c. DerivedData Cache

DerivedData caching can speed up incremental builds but is fragile:

```yaml
- name: Cache DerivedData
  uses: actions/cache@v4
  with:
    path: ~/Library/Developer/Xcode/DerivedData
    key: deriveddata-${{ runner.os }}-${{ hashFiles('project.yml', '**/*.swift') }}
    restore-keys: |
      deriveddata-${{ runner.os }}-
```

**Recommendation:** Skip DerivedData caching initially. XcodeGen regenerates the `.xcodeproj` each run, which can invalidate DerivedData. For a project of Transy's size (~15 Swift files), clean builds are fast enough (~30-60 seconds). DerivedData caching is more valuable for large projects with many SPM dependencies.

---

## 4. xcodebuild Commands

### Build

```bash
xcodebuild build \
  -scheme Transy \
  -destination 'platform=macOS' \
  -configuration Debug \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  | xcbeautify --renderer github-actions
```

**Key flags:**
- `CODE_SIGN_IDENTITY="-"` — ad-hoc sign (no certificate needed)
- `CODE_SIGNING_REQUIRED=NO` — don't require signing on CI
- `CODE_SIGNING_ALLOWED=NO` — prevent signing errors
- `xcbeautify --renderer github-actions` — formats xcodebuild output with GitHub Actions annotations

### Test

```bash
xcodebuild test \
  -scheme Transy \
  -destination 'platform=macOS' \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  | xcbeautify --renderer github-actions
```

### Platform Destination

For macOS native apps, use:
- `'platform=macOS'` — builds for the host macOS
- Do **NOT** use `'platform=macOS,arch=arm64'` unless you need to force architecture. The runner's native arch (arm64 on `macos-14`/`macos-15`) is used automatically.

---

## 5. Swift Testing Framework on CI

### How It Works with xcodebuild

Swift Testing (the `import Testing` / `@Test` / `#expect` framework) is fully integrated into Xcode 16+ and requires **no special xcodebuild flags**. The standard `xcodebuild test` command discovers and runs both XCTest and Swift Testing tests automatically.

Transy's tests use Swift Testing exclusively (`import Testing`, `@Suite`, `@Test`, `#expect`), which is correct for a Swift 6.0 project.

### Gotchas

| Issue | Detail | Mitigation |
|-------|--------|------------|
| **Xcode version requirement** | Swift Testing requires Xcode 16.0+. Xcode 15.x does NOT support it. | Use `macos-15` runner (Xcode 16.0+ pre-installed) |
| **Test discovery** | Swift Testing uses compile-time macros for discovery, not runtime reflection like XCTest. Works automatically. | No action needed |
| **Parallel execution** | Swift Testing runs tests in parallel by default. Tests must be isolated. | Transy's tests use value types (`struct`), already safe |
| **xcbeautify support** | xcbeautify 3.1.4 (pre-installed) supports Swift Testing output format | No action needed |
| **No `setUp`/`tearDown`** | Swift Testing uses `init`/`deinit` instead. Already handled in Transy's tests. | No action needed |
| **Result bundle** | For detailed test results, add `-resultBundlePath TestResults.xcresult` | Optional — useful for CI artifact upload |

**Confidence:** HIGH — verified from Swift Testing source repo, Apple docs, and Transy's existing test files.

---

## 6. SwiftLint Integration on CI

### Running SwiftLint

SwiftLint 0.63.2 is pre-installed on `macos-15`. No installation needed.

```yaml
- name: SwiftLint
  run: swiftlint lint --strict --reporter github-actions-logging
```

**Key flags:**
- `--strict` — treat warnings as errors (fail the build on any violation)
- `--reporter github-actions-logging` — outputs violations as GitHub Actions annotations that appear inline on PR diffs

### Recommended `.swiftlint.yml` for Swift 6 / SwiftUI

```yaml
# .swiftlint.yml

# Only lint project source code
included:
  - Transy
  - TransyTests

excluded:
  - Transy.xcodeproj
  - TransyUITests

# Disable rules that conflict with SwiftUI patterns
disabled_rules:
  - trailing_comma            # SwiftUI preview providers often use trailing commas
  - type_body_length          # SwiftUI views can be long with modifiers
  - function_body_length      # body property can be lengthy in complex views
  - file_length               # SwiftUI files with previews can be long

# Enable useful opt-in rules
opt_in_rules:
  - empty_count               # Prefer .isEmpty over .count == 0
  - closure_spacing           # Consistent closure spacing
  - contains_over_filter_count
  - contains_over_filter_is_empty
  - contains_over_first_not_nil
  - contains_over_range_nil_comparison
  - discouraged_optional_boolean
  - empty_string              # Prefer .isEmpty over == ""
  - first_where               # Prefer .first(where:) over .filter { }.first
  - flatmap_over_map_reduce
  - last_where
  - modifier_order            # Consistent modifier order
  - overridden_super_call
  - prefer_self_in_static_references
  - prefer_self_type_over_type_of_self
  - private_action
  - private_outlet
  - sorted_first_last         # Use .min()/.max() instead of .sorted().first/.last
  - unavailable_function
  - unowned_variable_capture
  - vertical_whitespace_closing_braces

# Customize rule thresholds
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

# Reporter for local use (overridden on CI with --reporter flag)
reporter: "xcode"
```

### SwiftUI-Specific Considerations

| Rule | Recommendation | Reason |
|------|---------------|--------|
| `trailing_comma` | Disable | SwiftUI builders often leave trailing commas |
| `type_body_length` | Disable or raise limit | SwiftUI `View` structs with complex layouts exceed defaults |
| `function_body_length` | Disable or raise limit | `var body: some View` can legitimately be long |
| `large_tuple` | Keep enabled | Encourages proper model types |
| `modifier_order` | Enable (opt-in) | Enforces consistent SwiftUI modifier ordering |
| `identifier_name` | Customize min length | SwiftUI uses short names like `x`, `y`, `id` |

---

## 7. SwiftFormat Integration on CI

### Running SwiftFormat

SwiftFormat 0.59.1 is pre-installed on `macos-15`. No installation needed.

```yaml
- name: SwiftFormat
  run: swiftformat --lint . --reporter github-actions-log
```

**Key flags:**
- `--lint` — check mode, no files modified, returns non-zero exit code on violations
- `--reporter github-actions-log` — outputs violations as GitHub Actions annotations

### Recommended `.swiftformat` Configuration

```
# .swiftformat

# Swift version
--swiftversion 6.0

# Language mode (Swift 6 strict concurrency)
--languagemode 6

# File options
--exclude Transy.xcodeproj,TransyUITests,.build,DerivedData

# Formatting options
--indent 4
--indentcase false
--wrapcollections before-first
--wraparguments before-first
--wrapparameters before-first
--maxwidth 150
--semicolons never
--commas always
--stripunusedargs closure-only
--self init-only
--header strip

# Disable rules that conflict with project style or are too aggressive
--disable acronyms
--disable blankLineAfterSwitchCase
--disable wrapSwitchCases

# Enable rules relevant to Swift Testing
--enable redundantSwiftTestingSuite
--enable swiftTestingTestCaseNames
```

### Sharing Config Between Local and CI

Both `.swiftlint.yml` and `.swiftformat` are committed to the repo root. They are automatically picked up by both local tool invocations and CI:

- **Local:** Developers run `swiftlint lint` and `swiftformat --lint .` from the repo root
- **CI:** The workflow runs the same commands from the checkout directory

No separate CI config files needed. The `--reporter` flag is the only CI-specific addition (passed as a command-line argument, not in the config file).

---

## 8. Complete Workflow YAML

### Implementation

```yaml
# .github/workflows/ci.yml
name: CI

on:
  pull_request:
    branches: [main]
  push:
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
        run: swiftformat --lint . --reporter github-actions-log

  build-and-test:
    name: Build & Test
    runs-on: macos-15
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0  # Needed for git describe (version from tag)

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

### Design Decisions

1. **Two parallel jobs** (`lint` + `build-and-test`): Linting is fast and doesn't need XcodeGen. Running it in parallel provides faster feedback on style violations.

2. **`concurrency` group with `cancel-in-progress`**: Cancels in-flight CI runs when a new push arrives on the same branch/PR. Saves macOS runner minutes (which are 10x more expensive than Linux).

3. **`fetch-depth: 0`**: Required because the `project.yml` has a post-build script that runs `git describe --tags` to set the version number. Shallow clones would fail this.

4. **`HOMEBREW_NO_AUTO_UPDATE=1`**: Prevents Homebrew from self-updating before installing XcodeGen. Saves 30-60 seconds per run.

5. **No Xcode selection step**: The default Xcode 16.4 on `macos-15` is compatible with Swift 6.0 and macOS 15.0 deployment target.

6. **Separate build and test steps**: Build failures are distinct from test failures in the workflow UI, making debugging easier.

---

## 9. Gotchas & Pitfalls

### Critical

| Gotcha | Detail | Solution |
|--------|--------|----------|
| **macOS runner cost** | macOS runners cost 10x Linux runners on GitHub Actions | Use `concurrency` to cancel stale runs. Keep jobs minimal. |
| **Code signing on CI** | xcodebuild may fail with signing errors on CI | Always pass `CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO` |
| **Shallow clone + git describe** | `actions/checkout@v4` defaults to `fetch-depth: 1` (shallow). `git describe --tags` fails. | Use `fetch-depth: 0` for full history |
| **XcodeGen not pre-installed** | Unlike SwiftLint/SwiftFormat, XcodeGen must be installed | `brew install xcodegen` with `HOMEBREW_NO_AUTO_UPDATE=1` |

### Moderate

| Gotcha | Detail | Solution |
|--------|--------|----------|
| **xcbeautify pipe exit code** | Piping to xcbeautify can mask xcodebuild's exit code | Use `set -o pipefail` in the shell (GitHub Actions bash uses this by default) |
| **SwiftFormat/SwiftLint version drift** | Pre-installed versions may update on runner image updates | Pin versions in a comment or document expectations. Not critical for linting. |
| **Accessibility permission in tests** | Tests that trigger CGEvent or Accessibility APIs will fail on CI (no UI session) | Transy's tests use mocks/stubs for these APIs. Keep it that way. |
| **Translation.framework in tests** | On-device Translation framework may not be available on CI runners | Mock the translation layer in tests. Don't test Apple's framework. |

### Minor

| Gotcha | Detail | Solution |
|--------|--------|----------|
| **DerivedData cleanup** | XcodeGen can sometimes cause stale DerivedData issues | Use `xcodebuild -derivedDataPath ./DerivedData` for isolated builds if issues arise |
| **Xcode version matrix** | Testing against multiple Xcode versions adds CI time | Unnecessary for Transy. One Xcode version is sufficient. |

---

## 10. Recommendation

**Use the workflow YAML from Section 8 as-is.** It covers all requirements:

- ✅ Runs on PRs to `main`
- ✅ Generates Xcode project from `project.yml`
- ✅ Builds for macOS
- ✅ Runs Swift Testing unit tests
- ✅ Enforces SwiftLint (strict mode, GitHub annotations)
- ✅ Enforces SwiftFormat (lint mode, GitHub annotations)
- ✅ Cancels stale runs
- ✅ No code signing issues
- ✅ Full git history for version tag

**Total estimated CI time:** ~2-4 minutes per run (lint: ~30s, build: ~60-90s, test: ~30s, XcodeGen install: ~15s).

---

## Sources

| Source | Confidence | What It Provided |
|--------|-----------|-----------------|
| [actions/runner-images macos-15 README](https://github.com/actions/runner-images/blob/main/images/macos/macos-15-Readme.md) | HIGH | Runner specs, pre-installed tools, Xcode versions |
| [actions/runner-images macos-14 README](https://github.com/actions/runner-images/blob/main/images/macos/macos-14-Readme.md) | HIGH | macOS 14 deprecation timeline |
| [SwiftLint README](https://github.com/realm/SwiftLint) | HIGH | Configuration, reporters, CI integration |
| [SwiftFormat README](https://github.com/nicklockwood/SwiftFormat) | HIGH | Lint mode, config file format, GitHub Actions integration |
| [create-dmg README](https://github.com/create-dmg/create-dmg) | HIGH | DMG creation options |
| [Swift Testing repo](https://github.com/swiftlang/swift-testing) | HIGH | Framework capabilities, Xcode 16 requirement |
| Transy project files (`project.yml`, test files) | HIGH | Project structure, test framework usage |

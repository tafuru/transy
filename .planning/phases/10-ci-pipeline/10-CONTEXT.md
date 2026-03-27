# Phase 10: CI Pipeline - Context

**Gathered:** 2025-07-22
**Status:** Ready for planning

<domain>
## Phase Boundary

This phase delivers a GitHub Actions CI workflow that validates every PR targeting `main`. It covers SwiftLint, SwiftFormat, build, and test — the four checks specified in CI-01 through CI-04. Existing code is brought into compliance as part of initial setup.

</domain>

<decisions>
## Implementation Decisions

### SwiftLint Configuration
- **D-01:** Strict ruleset — default rules plus opt-in rules (`empty_count`, `first_where`, `modifier_order`, etc.). Line length set to 150.
- **D-02:** SwiftUI-specific rules disabled: `type_body_length`, `function_body_length` (SwiftUI views naturally produce longer bodies).
- **D-03:** All existing code checked — no grandfathered exclusions. Fix all warnings in the initial PR.

### SwiftFormat Configuration
- **D-04:** Indent style: 4 spaces (matches `project.yml` `indentWidth: 4`).
- **D-05:** Disable rules that conflict with SwiftLint: `redundantSelf`, `trailingCommas`, and any other overlapping rules.
- **D-06:** Apply to all existing code — no file exclusions.

### CI Workflow Structure
- **D-07:** Trigger: `on: pull_request` targeting `main` only. No push triggers (branch protection already blocks direct pushes).
- **D-08:** Two parallel jobs: `lint` (SwiftLint + SwiftFormat) and `build-and-test` (xcodegen + xcodebuild build + test).
- **D-09:** All jobs are required status checks — lint failures block merge, same as build/test failures.
- **D-10:** Runner: `macos-15` (SwiftLint, SwiftFormat, xcbeautify pre-installed; only XcodeGen needs `brew install`).

### Agent's Discretion
- Specific opt-in SwiftLint rules beyond the ones mentioned — agent may add reasonable rules that improve code quality for Swift 6 / SwiftUI
- SwiftFormat rules to disable beyond `redundantSelf` and `trailingCommas` — agent should resolve any conflicts found during testing
- Whether to use `--strict` flag on SwiftLint (treats warnings as errors)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### CI Research
- `.planning/research/ci-pipeline.md` — Complete workflow YAML templates, runner capabilities, tool versions, XcodeGen install strategy

### Project Configuration
- `project.yml` — XcodeGen project definition (indentWidth: 4, Swift 6, macOS 15, target structure)

### Requirements
- `.planning/REQUIREMENTS.md` §CI — CI-01 (SwiftLint), CI-02 (SwiftFormat), CI-03 (build), CI-04 (test)

### Development Guidelines
- `.github/DEVELOPMENT.md` — Branch protection rules, PR workflow, closing rules

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- None — no existing CI configuration or linter configs in the repo

### Established Patterns
- `project.yml` defines 3 targets: Transy, TransyTests, TransyUITests
- Tests use Swift Testing framework (`import Testing`, `@Suite`, `@Test`, `#expect`)
- Post-build script uses `git describe --tags` for version — CI needs `fetch-depth: 0`
- 14 test files in TransyTests covering managers, detectors, coordinators, settings

### Integration Points
- `.swiftlint.yml` and `.swiftformat` config files at repo root
- `.github/workflows/ci.yml` for the workflow definition
- GitHub branch protection ruleset (ID: 14329617) — add required status checks after workflow is verified

</code_context>

<specifics>
## Specific Ideas

- Use `xcbeautify` to pipe xcodebuild output for readable CI logs
- Use `HOMEBREW_NO_AUTO_UPDATE=1` for faster XcodeGen install
- Handle `fetch-depth: 0` so the post-build version script works in CI

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 10-ci-pipeline*
*Context gathered: 2025-07-22*

# Phase 11: Release Automation - Context

**Gathered:** 2025-07-22
**Status:** Ready for planning

<domain>
## Phase Boundary

This phase delivers a GitHub Actions workflow that builds a release DMG and publishes a GitHub Release when a version tag is pushed. It covers the full pipeline: tag trigger → Release build → DMG packaging → GitHub Release creation with auto-generated notes and DMG asset.

</domain>

<decisions>
## Implementation Decisions

### Trigger Strategy
- **D-01:** Tag push trigger (`on: push: tags: [v*]`). Pushing a tag like `v0.4.0` fires the workflow. Works from CLI (`git tag && git push`) or GitHub UI.
- **D-02:** The workflow creates the GitHub Release (not the other way around). No `on: release` event needed.

### DMG Creation
- **D-03:** Use `create-dmg` (installed via Homebrew). Produces a drag-to-Applications layout with icon positioning.
- **D-04:** Handle `create-dmg` exit code 2 as success (DMG created but Finder layout couldn't be set — common on CI). Only fail on exit codes other than 0 and 2.

### Release Notes
- **D-05:** Auto-generated release notes using `gh release create --generate-notes`.
- **D-06:** Add `.github/release.yml` to categorize PRs into Features, Bug Fixes, Maintenance, Documentation sections.

### Pre-release Support
- **D-07:** Tags containing a hyphen (e.g., `v0.4.0-beta.1`, `v0.5.0-rc.1`) automatically get the `--prerelease` flag on the GitHub Release. Detected via shell pattern match on the tag name.

### Agent's Discretion
- Build configuration details (Release vs Archive approach — research recommends `xcodebuild build -configuration Release` for unsigned)
- DMG window dimensions and icon positions (research provides sensible defaults)
- Whether to add an `upload-artifact` step for build debugging
- Whether to add a test step before the release build

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Release Research
- `.planning/research/release-automation.md` — Complete workflow YAML templates, create-dmg usage, exit code handling, pre-release pattern, gotchas

### CI Reference (Phase 10)
- `.github/workflows/ci.yml` — Existing CI workflow with shared patterns (XcodeGen install, xcodebuild flags, xcbeautify, code signing overrides)
- `.planning/phases/10-ci-pipeline/10-CONTEXT.md` — CI decisions (runner, Homebrew env vars, xcbeautify usage)

### Project Configuration
- `project.yml` — XcodeGen config with post-build script for version injection from git tags

### Development Guidelines
- `.github/DEVELOPMENT.md` — Branch protection, PR workflow, release tagging procedures

### Requirements
- `.planning/REQUIREMENTS.md` §REL — REL-01 (automated build), REL-02 (DMG with layout), REL-03 (upload as asset)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `.github/workflows/ci.yml` — Existing workflow with xcodebuild patterns, Homebrew caching env vars, XcodeGen install, code sign overrides
- `project.yml` post-build script — Already sets `CFBundleShortVersionString` from `git describe --tags`, so Release builds get the correct version automatically

### Established Patterns
- `HOMEBREW_NO_AUTO_UPDATE=1` and `HOMEBREW_NO_INSTALL_CLEANUP=1` env vars for faster Homebrew installs
- `CODE_SIGN_IDENTITY="-"` + `CODE_SIGNING_REQUIRED=NO` + `CODE_SIGNING_ALLOWED=NO` for unsigned builds
- `xcbeautify --renderer github-actions` for readable CI logs
- `fetch-depth: 0` required for git describe version script

### Integration Points
- `.github/workflows/release.yml` — New workflow file
- `.github/release.yml` — Release notes categorization config
- GitHub Releases page — Where DMG assets are published

</code_context>

<specifics>
## Specific Ideas

- Version extraction from tag: `echo "version=${GITHUB_REF_NAME#v}" >> "$GITHUB_OUTPUT"`
- DMG naming convention: `Transy-{version}.dmg` (e.g., `Transy-0.4.0.dmg`)
- `permissions: contents: write` required for creating releases via `GITHUB_TOKEN`
- `--verify-tag` flag on `gh release create` as a safety check

</specifics>

<deferred>
## Deferred Ideas

- **Code signing & notarization** — Add when the app needs broader distribution. Requires Apple Developer certificate, keychain management in CI, `xcrun notarytool`. Significant addition (~50 lines).
- **CHANGELOG.md** — Manual curated changelog. Consider when auto-generated notes become insufficient.

</deferred>

---

*Phase: 11-release-automation*
*Context gathered: 2025-07-22*

# Phase 11: Release Automation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2025-07-22
**Phase:** 11-release-automation
**Areas discussed:** Trigger Strategy, DMG Creation, Release Notes, Pre-release Support

---

## Trigger Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Tag push trigger (`on: push: tags: v*`) | Push a tag to trigger the full pipeline: build → DMG → Release creation. Works from CLI or UI. | ✓ |
| Release event trigger (`on: release: types: [created]`) | Create a Release from GitHub UI first, then workflow builds DMG and uploads to existing Release. | |

**User's choice:** Tag push trigger — workflow creates the GitHub Release automatically
**Notes:** User selected for full automation. The workflow handles everything end-to-end.

---

## DMG Creation

| Option | Description | Selected |
|--------|-------------|----------|
| create-dmg | Homebrew-installable tool with Finder layout (icon positioning, Applications link). Has exit code 2 gotcha on CI. | ✓ |
| hdiutil (raw) | Built-in, no dependencies. Functional DMG but no window cosmetics. | |
| Agent's discretion | Let the agent decide based on research | |

**User's choice:** create-dmg with exit code 2 handling
**Notes:** None

---

## Release Notes

| Option | Description | Selected |
|--------|-------------|----------|
| Auto-generated + .github/release.yml | PR titles auto-categorized into Features, Bug Fixes, Maintenance, Documentation | ✓ |
| Auto-generated only | Simple list of PR titles without categorization | |
| Agent's discretion | Let the agent decide | |

**User's choice:** Auto-generated with category configuration
**Notes:** None

---

## Pre-release Support

| Option | Description | Selected |
|--------|-------------|----------|
| Pre-release detection | Tags with hyphens (e.g., v0.4.0-beta.1) auto-flagged as pre-release | ✓ |
| No pre-release support | All tags treated as final releases | |

**User's choice:** Pre-release detection based on tag pattern
**Notes:** None

---

## Agent's Discretion

- Build approach (xcodebuild build vs archive — research recommends build for unsigned)
- DMG window dimensions and icon positions
- Whether to add upload-artifact or test step

## Deferred Ideas

- Code signing & notarization (future phase when broader distribution needed)
- CHANGELOG.md (when auto-generated notes become insufficient)

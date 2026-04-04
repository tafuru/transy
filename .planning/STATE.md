---
gsd_state_version: 1.0
milestone: v0.4.0
milestone_name: DevOps & Improvements
status: Ready to plan
stopped_at: Phase 12 planned (2 plans, 2 waves)
last_updated: "2026-04-04T02:57:36.798Z"
progress:
  total_phases: 4
  completed_phases: 3
  total_plans: 5
  completed_plans: 5
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-25)

**Core value:** Selected text turns into a natural translation almost instantly without breaking the user's reading flow.
**Current focus:** Phase 12 — clipboard-monitoring

## Current Position

Phase: 13
Plan: Not started

## Performance Metrics

**Velocity (v0.1.0):**

- Total plans completed: 9
- Average duration: 26.1 min
- Total execution time: 199 min

**Velocity (v0.2.0):**

- Total plans completed: 4
- Average duration: 3.5 min
- Total execution time: 14.1 min

| Phase | Plan | Duration | Tasks | Files | Completed |
|-------|------|----------|-------|-------|-----------|
| 05    | 00   | 103s (1.7m) | 1     | 3     | 2026-03-16T14:55:14Z |
| 06    | 00   | 97s (1.6m)  | 2     | 2     | 2026-03-20T16:46:31Z |
| 06    | 01   | 480s (8.0m) | 2     | 1     | 2026-03-20T16:58:43Z |
| 08    | 01   | 72s (1.2m)  | 2     | 2     | 2026-03-23T13:21:00Z |
| Phase 10-ci-pipeline P02 | 65 | 1 tasks | 1 files |
| Phase 10 P01 | 88 | 2 tasks | 5 files |
| Phase 11 P01 | 98 | 2 tasks | 2 files |

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- [v0.2.0 - Phase 6]: PopupPositionCalculator uses Foundation types only (CGPoint, CGSize, CGRect) — no AppKit dependency for testability
- [v0.2.0 - Phase 5]: PopupText changed from private to internal for @testable import access in test suite
- [v0.1.0]: Apple Translation framework chosen as backend — on-device speed, privacy, macOS-native integration
- [v0.1.0]: LSUIElement set via Info.plist, not entitlements
- [v0.1.0]: Popup is NSPanel with `.nonactivatingPanel` styleMask — SwiftUI `WindowGroup` is a hard anti-pattern
- [v0.1.0]: `project.yml` managed by xcodegen is the single source of truth for `Transy.xcodeproj`
- [v0.1.0]: Three-tier language reconciliation (exact → languageCode → fallback) for region-qualified OS locales
- [v0.1.0]: System Settings deep link with `.extension` suffix for macOS 13+
- [Phase 06]: PopupPositionCalculator uses Foundation types only — no AppKit dependency for testability
- [Phase 06]: Cursor location captured once at trigger time (NSEvent.mouseLocation) — popup stays anchored to original cursor position through content changes
- [Phase 06]: NSWindow.didResizeNotification used for content height change observation — lightweight, no KVO or Combine needed
- [Phase 08]: AX permission state is sole determinant for showing guidance — no UserDefaults flag
- [Phase 10-ci-pipeline]: Two parallel CI jobs (lint, build-and-test) on macos-15 with no dependency between them
- [Phase 10-ci-pipeline]: fetch-depth: 0 only on build-and-test job for git describe --tags version script
- [Phase 10]: D-01: Strict SwiftLint with 150-char line limit and 17 opt-in rules
- [Phase 10]: D-05: SwiftFormat disables redundantSelf/trailingCommas to avoid SwiftLint conflicts
- [Phase 11]: D-01: Tag push trigger (on: push: tags: [v*]) for release workflow
- [Phase 11]: D-03: create-dmg via Homebrew for drag-to-Applications DMG layout with exit code 2 tolerance
- [Phase 11]: D-05: Auto-generated release notes via gh release create --generate-notes with PR categorization

### Pending Todos

- Todo: track unresolved Translation framework cancellation latency across re-trigger/dismiss flows

### Blockers/Concerns

- Known limitation: Translation framework cancellation latency can still make a short request feel delayed after a longer one
- Apple Translation framework requires macOS 15+ — this remains the hard deployment-target floor

## Session Continuity

Last session: 2026-04-04T02:15:00.000Z
Stopped at: Phase 12 planned (2 plans, 2 waves)
Resume file: .planning/phases/12-clipboard-monitoring/12-01-PLAN.md

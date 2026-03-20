---
gsd_state_version: 1.0
milestone: v0.1
milestone_name: milestone
status: completed
stopped_at: Completed 06-01-PLAN.md
last_updated: "2026-03-20T16:59:57.104Z"
last_activity: 2026-03-20 — Completed 06-01-PLAN.md (cursor-proximate positioning integration)
progress:
  total_phases: 2
  completed_phases: 2
  total_plans: 4
  completed_plans: 4
  percent: 100
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-16)

**Core value:** Selected text turns into a natural translation almost instantly without breaking the user's reading flow.
**Current focus:** v0.2.0 Popup UX Polish — multi-line scrollable popup with cursor-proximate positioning

## Current Position

Phase: Phase 6 (Popup Positioning) — complete
Plan: 06-01 (completed) — all plans in v0.2.0 complete
Status: v0.2.0 Popup UX Polish milestone complete
Last activity: 2026-03-20 — Completed 06-01-PLAN.md (cursor-proximate positioning integration)

Progress: [██████████] 100% (4/4 plans complete)

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

### Pending Todos

- Todo: track unresolved Translation framework cancellation latency across re-trigger/dismiss flows

### Blockers/Concerns

- Known limitation: Translation framework cancellation latency can still make a short request feel delayed after a longer one
- Apple Translation framework requires macOS 15+ — this remains the hard deployment-target floor

## Session Continuity

Last session: 2026-03-20T16:59:57.102Z
Stopped at: Completed 06-01-PLAN.md
Resume file: None

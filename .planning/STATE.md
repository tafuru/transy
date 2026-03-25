---
gsd_state_version: 1.0
milestone: v0.4.0
milestone_name: DevOps & Improvements
status: roadmap
stopped_at: Roadmap created, ready to plan Phase 10
last_updated: "2026-03-25T16:00:00.000Z"
last_activity: 2026-03-25 — v0.4.0 roadmap created (4 phases, 12 requirements)
progress:
  total_phases: 4
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-25)

**Core value:** Selected text turns into a natural translation almost instantly without breaking the user's reading flow.
**Current focus:** v0.4.0 DevOps & Improvements — CI/CD, release automation, clipboard monitoring, translation model DL UI

## Current Position

Milestone: v0.4.0 DevOps & Improvements
Phase: 10 of 13 (CI Pipeline) — ready to plan
Plan: —
Status: Ready to plan Phase 10
Last activity: 2026-03-25 — v0.4.0 roadmap created

Progress: [░░░░░░░░░░] 0%

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

### Pending Todos

- Todo: track unresolved Translation framework cancellation latency across re-trigger/dismiss flows

### Blockers/Concerns

- Known limitation: Translation framework cancellation latency can still make a short request feel delayed after a longer one
- Apple Translation framework requires macOS 15+ — this remains the hard deployment-target floor

## Session Continuity

Last session: 2026-03-23T13:19:19.049Z
Stopped at: Completed 08-01-PLAN.md
Resume file: None

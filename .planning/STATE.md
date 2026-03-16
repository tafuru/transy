---
gsd_state_version: 1.0
milestone: v0.2.0
milestone_name: Popup UX Polish
status: planning
stopped_at: Defining requirements
last_updated: "2026-03-16T12:25:00.000Z"
last_activity: 2026-03-16 — Milestone v0.2.0 started
progress:
  total_phases: 0
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-16)

**Core value:** Selected text turns into a natural translation almost instantly without breaking the user's reading flow.
**Current focus:** Defining v0.2.0 requirements — popup UX improvements

## Current Position

Phase: Not started (defining requirements)
Plan: —
Status: Defining requirements
Last activity: 2026-03-16 — Milestone v0.2.0 started

Progress: [░░░░░░░░░░] 0%

## Performance Metrics

**Velocity (v0.1.0):**
- Total plans completed: 9
- Average duration: 26.1 min
- Total execution time: 199 min

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- [v0.1.0]: Apple Translation framework chosen as backend — on-device speed, privacy, macOS-native integration
- [v0.1.0]: LSUIElement set via Info.plist, not entitlements
- [v0.1.0]: Popup is NSPanel with `.nonactivatingPanel` styleMask — SwiftUI `WindowGroup` is a hard anti-pattern
- [v0.1.0]: `project.yml` managed by xcodegen is the single source of truth for `Transy.xcodeproj`
- [v0.1.0]: Three-tier language reconciliation (exact → languageCode → fallback) for region-qualified OS locales
- [v0.1.0]: System Settings deep link with `.extension` suffix for macOS 13+

### Pending Todos

- Todo: track unresolved Translation framework cancellation latency across re-trigger/dismiss flows

### Blockers/Concerns

- Known limitation: Translation framework cancellation latency can still make a short request feel delayed after a longer one
- Apple Translation framework requires macOS 15+ — this remains the hard deployment-target floor

## Session Continuity

Last session: 2026-03-16
Stopped at: Milestone v0.2.0 — defining requirements
Resume file: None

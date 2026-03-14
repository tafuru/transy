---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: planning
stopped_at: Phase 2 context gathered
last_updated: "2026-03-14T08:22:38.414Z"
last_activity: 2026-03-14 — Phase 1 completed, verified, and marked complete
progress:
  total_phases: 4
  completed_phases: 1
  total_plans: 2
  completed_plans: 2
  percent: 25
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-14)

**Core value:** Selected text turns into a natural translation almost instantly without breaking the user's reading flow.
**Current focus:** Phase 2 — Trigger & Popup

## Current Position

Phase: 2 of 4 (Trigger & Popup)
Plan: 0 of 3 in current phase
Status: Ready to plan
Last activity: 2026-03-14 — Phase 1 completed, verified, and marked complete

Progress: [██░░░░░░░░] 25%

## Performance Metrics

**Velocity:**
- Total plans completed: 2
- Average duration: 17.5 min
- Total execution time: 35 min

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 1. App Shell | 2 | 35 min | 17.5 min |

**Recent Trend:**
- Last 2 plans: 15 min, 20 min
- Trend: Stable

*Updated after each plan completion*

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- [Pre-phase]: Apple Translation framework chosen as backend (not DeepL) — on-device speed, privacy, macOS-native integration
- [Pre-phase]: Apple Translation is sandbox-compatible, but the chosen global-monitoring approach and its capability model must be validated in Phase 2 before locking the final sandbox configuration
- [Pre-phase]: LSUIElement set via Info.plist, not entitlements (common mistake to avoid)
- [Pre-phase]: Popup must be NSPanel with `.nonactivatingPanel` styleMask from day one — SwiftUI `WindowGroup` is a hard anti-pattern there
- [Phase 01-app-shell]: `project.yml` managed by xcodegen is the single source of truth for `Transy.xcodeproj`
- [Phase 01-app-shell]: `GENERATE_INFOPLIST_FILE: YES` is required on test targets when no explicit Info.plist path is provided
- [Phase 01-app-shell]: `ENABLE_APP_SANDBOX: NO` and no entitlements file keeps future global event monitoring viable for Phase 2
- [Phase 01-app-shell]: `.menuBarExtraStyle(.menu)` is required to get a native dropdown instead of a floating panel
- [Phase 01-app-shell]: `NSApp.activate()` must precede `openSettings()` in an `LSUIElement` app so the Settings window surfaces above the current app
- [Phase 01-app-shell]: Use a SwiftUI `Settings` scene, not `WindowGroup`, for the single-instance settings window and Cmd+, behavior

### Pending Todos

None yet.

### Blockers/Concerns

- Phase 2: Accessibility is required, and any additional privacy permissions depend on the final monitoring API; onboarding must validate and explain the chosen path explicitly
- Phase 2: Clipboard read must be delayed ~80ms after trigger fires because the source app has not written selection contents yet when the monitor first fires
- Phase 3: Apple Translation framework requires macOS 15+ — this remains the hard deployment-target floor

## Session Continuity

Last session: 2026-03-14T08:22:38.409Z
Stopped at: Phase 2 context gathered
Resume file: .planning/phases/02-trigger-popup/02-CONTEXT.md

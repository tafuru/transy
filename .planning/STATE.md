---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: planning
stopped_at: Completed 02-01-PLAN.md
last_updated: "2026-03-14T09:23:12.805Z"
last_activity: 2026-03-14 — 02-01-PLAN.md complete (permissions guidance subsystem)
progress:
  total_phases: 4
  completed_phases: 1
  total_plans: 5
  completed_plans: 3
  percent: 60
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-14)

**Core value:** Selected text turns into a natural translation almost instantly without breaking the user's reading flow.
**Current focus:** Phase 2 — Trigger & Popup

## Current Position

Phase: 2 of 4 (Trigger & Popup)
Plan: 1 of 3 in current phase (1 complete)
Status: Executing
Last activity: 2026-03-14 — 02-01-PLAN.md complete (permissions guidance subsystem)

Progress: [██████░░░░] 60%

## Performance Metrics

**Velocity:**
- Total plans completed: 3
- Average duration: 12 min
- Total execution time: 36 min

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 1. App Shell | 2 | 35 min | 17.5 min |

**Recent Trend:**
- Last 2 plans: 15 min, 20 min
- Trend: Stable

*Updated after each plan completion*
| Phase 02-trigger-popup P01 | 1 | 2 tasks | 2 files |

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
- [Phase 02-trigger-popup]: `NSEvent.addGlobalMonitorForEvents` with Accessibility-only permission is the chosen monitoring path; no Input Monitoring flow is planned
- [Phase 02-trigger-popup]: First-time missing Accessibility guidance is surfaced on explicit menu open, not at app launch
- [Phase 02-trigger-popup]: After Accessibility is granted from System Settings, monitoring should auto-start without requiring a relaunch
- [Phase 02-trigger-popup]: `DoublePressDetector.record()` must use explicit state updates rather than `defer`, so a rapid triple-press fires exactly once
- [Phase 02-trigger-popup]: Swift 6 plans should use `MainActor.assumeIsolated` in NSEvent/Timer callbacks when the runtime guarantee is main-thread delivery
- [Phase 02-trigger-popup]: showIfNeeded() re-raises guidance window on every failed trigger attempt — no suppression after first show
- [Phase 02-trigger-popup]: AXIsProcessTrusted() used directly; AXIsProcessTrustedWithOptions(prompt:true) avoided to prevent generic macOS system prompt replacing custom guidance

### Pending Todos

- ✅ 02-01-PLAN.md complete (permissions guidance)
- Execute Wave 1: `02-02-PLAN.md` (trigger subsystem + Wave 0 tests)
- Execute Wave 2 plan after Wave 1 passes: `02-03-PLAN.md` (popup wiring + human smoke test)

### Blockers/Concerns

- Phase 2: Human smoke-test remains required for focus non-theft, popup dismissal, clipboard restore, and permission guidance behavior
- Phase 2: Validate the Accessibility System Settings deep link and the post-grant auto-retry path on macOS 15 during execution
- Phase 2: Clipboard read must be delayed ~80ms after trigger fires because the source app has not written selection contents yet when the monitor first fires
- Phase 3: Apple Translation framework requires macOS 15+ — this remains the hard deployment-target floor

## Session Continuity

Last session: 2026-03-14T09:23:07.695Z
Stopped at: Completed 02-01-PLAN.md
Resume file: None

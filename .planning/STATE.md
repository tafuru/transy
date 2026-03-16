---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: executing
stopped_at: Phase 4 complete — all plans executed and verified
last_updated: "2026-03-15T14:30:00.000Z"
last_activity: 2026-03-15 — Completed 04-02-PLAN.md (Settings UI, guidance, checkpoint fixes)
progress:
  total_phases: 4
  completed_phases: 4
  total_plans: 9
  completed_plans: 9
  percent: 100
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-14)

**Core value:** Selected text turns into a natural translation almost instantly without breaking the user's reading flow.
**Current focus:** Phase 4 complete — all phases executed and verified

## Current Position

Phase: 4 complete (2 of 2 plans complete)
Plan: 04-01 complete, 04-02 complete
Status: Phase 4 complete — settings UI, model guidance, and all checkpoint fixes verified
Last activity: 2026-03-15 — Completed 04-02-PLAN.md (Settings UI, guidance, checkpoint fixes)

Progress: [██████████] 100%

## Performance Metrics

**Velocity:**
- Total plans completed: 8
- Average duration: 26.1 min
- Total execution time: 199 min

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 1. App Shell | 2 | 35 min | 17.5 min |
| 2. Trigger & Popup | 3 | 44 min | 14.7 min |
| 3. Translation Loop | 2 | 1h 56m | 58.0 min |
| 4. Settings | 1 | 4 min | 4.0 min |

**Recent Trend:**
- Last 3 plans: 8 min, 1h 48m, 4 min
- Trend: Short Wave 0 TDD plan after intensive Phase 3 runtime validation

*Updated after each plan completion*
| Phase 03 P01 | 8 min | 3 tasks | 8 files |
| Phase 03 P02 | 1h 48m | 3 tasks | 10 files |
| Phase 04 P01 | 4 min | 2 tasks | 10 files |

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
- [Phase 02-trigger-popup]: DoublePressDetector.record() uses explicit nil-reset (not defer) so triple-press fires exactly once
- [Phase 02-trigger-popup]: HotkeyMonitor uses .intersection(.deviceIndependentFlagsMask) == .command to exclude Cmd+Shift+C
- [Phase 02-trigger-popup]: orderFrontRegardless() used for LSUIElement background-app popup visibility (orderFront(nil) is a silent no-op when app is not active)
- [Phase 02-trigger-popup]: Clipboard snapshot taken at first Cmd+C keyDown (before Task.sleep(80ms)) so restore yields original clipboard, not trigger selection
- [Phase 03]: Generic English preflight target is centralized as Locale.Language(identifier: 'en') until Phase 4 settings exist
- [Phase 03]: Visible source text uses trim-only normalization while availability preflight uses a collapsed-whitespace detection sample
- [Phase 03]: TranslationErrorMapper owns short inline copy so popup wiring never forwards raw framework descriptions
- [Phase 03]: TranslationCoordinator guards finish/fail writes with activeRequestID so stale completions cannot overwrite newer popup state
- [Phase 03]: Popup reuse stays at the NSPanel level, but the hosted SwiftUI subtree must be torn down on re-trigger and dismiss so translationTask restarts and cancels as quickly as AppKit allows
- [Phase 03]: Phase 3 ships the macOS 15-compatible translationTask path only; a Tahoe-only TranslationSession.cancel() experiment was removed after it showed no meaningful user-visible improvement
- [Phase 03]: Translation-framework cancellation latency remains a documented known limitation, not a hidden defect, while visible correctness requirements are considered satisfied
- [Phase 04]: Settings stays a single compact native pane; guidance appears only when relevant and may modestly expand the window
- [Phase 04]: Target-language choices come from Apple-supported languages with natural-language labels, default from OS preference, then persist independently afterward
- [Phase 04]: Settings auto-save immediately; the next request uses the new target while any active popup/request stays frozen
- [Phase 04]: Model guidance is absent when irrelevant, generic after a real missing-model event with unknown pair certainty, and only pair-specific when trusted known-pair context exists
- [Phase 04-01]: SettingsStore persists only Locale.Language.minimalIdentifier in UserDefaults; reconstructs full Locale.Language on read to avoid serialization complexity
- [Phase 04-01]: Target language defaults from OS preferred language on first run only; stored value wins over later OS language changes
- [Phase 04-01]: Request-time snapshot freezes target language for popup lifecycle; AppDelegate passes frozen TranslationAvailabilityClient to PopupController

### Pending Todos

- ✅ 02-01-PLAN.md complete (permissions guidance)
- ✅ 02-02-PLAN.md complete (trigger subsystem)
- ✅ 02-03-PLAN.md complete (popup wiring + human smoke test)
- ✅ 03-01-PLAN.md complete (translation foundation)
- ✅ 03-02-PLAN.md complete (popup translation wiring + accepted live verification)
- ✅ 04-01-PLAN.md complete (settings store + request snapshot wiring)
- ✅ 04-02-PLAN.md complete (settings UI + conditional model guidance + checkpoint fixes)
- Todo: track unresolved Translation framework cancellation latency across re-trigger/dismiss flows

### Blockers/Concerns

- Phase 4: Add target-language selection and model-install guidance without regressing LSUIElement popup behavior
- Phase 4: System Settings guidance action should prefer a conservative destination and still needs live validation for the exact Translation Languages landing behavior
- Known limitation: Translation framework cancellation latency can still make a short request feel delayed after a longer one, even though stale overwrite and late reappearance are fixed
- Phase 3: Apple Translation framework requires macOS 15+ — this remains the hard deployment-target floor

## Session Continuity

Last session: 2026-03-15T13:40:55.514Z
Stopped at: Checkpoint verification fixes for 04-02-PLAN.md
Resume file: None

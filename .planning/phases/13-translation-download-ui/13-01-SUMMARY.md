---
phase: 13-translation-download-ui
plan: 01
subsystem: translation
tags: [apple-translation-framework, swiftui, model-download, preflight]

# Dependency graph
requires: []
provides:
  - "Framework-native translation model download prompt (no manual System Settings guidance)"
  - "Simplified preflight with 4 cases: ready, unsupported, couldNotDetect, failed"
  - "Popup chain without settingsStore dependency"
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "session.translate() handles .supported models — framework shows built-in download prompt"

key-files:
  created: []
  modified:
    - Transy/Translation/TranslationAvailabilityClient.swift
    - Transy/Popup/PopupView.swift
    - Transy/Popup/PopupController.swift
    - Transy/AppDelegate.swift
    - Transy/Translation/TranslationErrorMapper.swift
    - Transy/Settings/SettingsStore.swift
    - Transy/Settings/GeneralSettingsView.swift
    - TransyTests/TranslationAvailabilityClientTests.swift
    - TransyTests/TranslationTaskConfigurationReloaderTests.swift
  deleted:
    - Transy/Settings/TranslationModelGuidance.swift
    - TransyTests/TranslationModelGuidanceTests.swift

key-decisions:
  - "D-07 resolved: TranslationSession.cancel() is macOS 26+ only; macOS 15 uses configuration.invalidate() which is already implemented — cancellation latency is an Apple framework limitation, not a Transy bug"

patterns-established:
  - "When LanguageAvailability returns .supported, let session.translate() proceed — the framework handles the download prompt natively"

requirements-completed: [TDL-01]

# Metrics
duration: 5min
completed: 2026-04-04
---

# Phase 13 Plan 01: Translation Download UI Summary

**Replace manual "Open Language & Region" model-download guidance with Translation framework's built-in download prompt; delete ~270 lines of guidance infrastructure**

## Performance

- **Duration:** 5 min (348s)
- **Started:** 2026-04-04T06:26:44Z
- **Completed:** 2026-04-04T06:32:32Z
- **Tasks:** 2
- **Files modified:** 9 modified, 2 deleted

## Accomplishments

- Removed `.missingModel` preflight short-circuit — `.supported` now maps to `.ready`, allowing `session.translate()` to proceed and trigger the framework's built-in download prompt
- Removed `settingsStore` dependency from entire popup chain (PopupView, LoadingPopupText, PopupController, AppDelegate)
- Deleted `TranslationModelGuidance.swift`, `TranslationModelGuidanceTests.swift`, and all related code from SettingsStore and GeneralSettingsView (~270 lines removed)
- Resolved D-07 pending todo: `TranslationSession.cancel()` is macOS 26+ only; existing `configuration.invalidate()` in `nextTranslationConfiguration()` is the correct macOS 15 approach

## Task Commits

Each task was committed atomically:

1. **Task 1: Remove .missingModel preflight short-circuit and settingsStore popup dependency** — `3b21507` (refactor)
2. **Task 2: Delete guidance infrastructure and clean up Settings** — `01d2da8` (feat)

## Files Created/Modified

- `Transy/Translation/TranslationAvailabilityClient.swift` — Removed `.missingModel` case; `.installed, .supported:` both map to `.ready`
- `Transy/Popup/PopupView.swift` — Removed settingsStore from PopupView, LoadingPopupText, translationAction; removed .missingModel switch case
- `Transy/Popup/PopupController.swift` — Removed settingsStore from show() signature and PopupView initializer
- `Transy/AppDelegate.swift` — Removed settingsStore argument from popupController.show() call
- `Transy/Translation/TranslationErrorMapper.swift` — Removed modelNotInstalled constant
- `Transy/Settings/SettingsStore.swift` — Removed missingModelContext property and recordMissingModel() method
- `Transy/Settings/GeneralSettingsView.swift` — Removed import Translation, guidanceState, guidance UI, openSystemSettings(), onChange(of: missingModelContext)
- `TransyTests/TranslationAvailabilityClientTests.swift` — Renamed supportedMapsToMissingModel → supportedMapsToReady; asserts .ready
- `TransyTests/TranslationTaskConfigurationReloaderTests.swift` — Removed settingsStore from PopupController.show() test call
- `Transy/Settings/TranslationModelGuidance.swift` — **DELETED** (guidance struct, GuidanceState, MissingModelContext)
- `TransyTests/TranslationModelGuidanceTests.swift` — **DELETED** (5 guidance tests)

## Decisions Made

- D-07 resolved: TranslationSession.cancel() is macOS 26+ only. The existing `configuration.invalidate()` pattern in `nextTranslationConfiguration()` is the correct macOS 15 approach. The cancellation latency pending todo is resolved — it's an Apple framework limitation, not something Transy can mitigate.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Fixed TranslationTaskConfigurationReloaderTests.swift calling old PopupController.show() signature**
- **Found during:** Task 2 (build/test verification)
- **Issue:** `TranslationTaskConfigurationReloaderTests.swift` still passed `settingsStore` and `mockSettingsStore` to `PopupController.show()` which no longer accepts that parameter
- **Fix:** Removed settingsStore setup and argument from the test's `popupDismissRemovesHostedContent()` function
- **Files modified:** `TransyTests/TranslationTaskConfigurationReloaderTests.swift`
- **Verification:** `make test` passes
- **Committed in:** `01d2da8` (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Test file not listed in plan's files_modified needed the same settingsStore removal. No scope creep.

## Issues Encountered

None — all planned work executed cleanly after the test fix.

## User Setup Required

None — no external service configuration required.

## Known Stubs

None — no stubs or placeholder data.

## Next Phase Readiness

- Phase 13 is the final phase of v0.4.0 milestone
- Translation model downloads are now handled by the framework's native UI
- All CI checks pass (swiftlint, build, test)

---
*Phase: 13-translation-download-ui*
*Completed: 2026-04-04*

---
phase: 04-settings
plan: 02
subsystem: settings
tags: [ui, guidance, picker, checkpoint]
requirements: [APP-02, APP-03]
dependency_graph:
  requires: [04-01]
  provides: [settings-ui, model-guidance, language-picker]
  affects: [SettingsView, SettingsStore, TranslationModelGuidance, PopupView, AppDelegate]
tech_stack:
  added: [SupportedLanguageOption, TranslationModelGuidance, MissingModelContext]
  patterns: [conditional-guidance, picker-reconciliation, runtime-relevance-recording]
key_files:
  created:
    - Transy/Settings/SupportedLanguageOption.swift
    - Transy/Settings/TranslationModelGuidance.swift
    - TransyTests/TranslationModelGuidanceTests.swift
  modified:
    - Transy/Settings/SettingsView.swift
    - Transy/Settings/SettingsStore.swift
    - Transy/Popup/PopupView.swift
    - Transy/Translation/TranslationAvailabilityClient.swift
    - Transy/AppDelegate.swift
    - Transy/Popup/PopupController.swift
decisions:
  - Picker selection managed via separate @State to handle async language loading
  - Stored target reconciled with supported options after language list loads
  - Fallback to first supported language if stored target not in supported list
  - Missing-model context recorded from runtime without mutating active popup
  - Guidance stays absent before relevance, generic after missing-model with unknown pair
  - Guidance copy includes explicit path to Translation Languages in System Settings
  - PreflightResult.missingModel distinguishes real missing models from other failures
  - System Settings action opens Language & Region pane with full path in copy
metrics:
  duration: TBD
  completed: 2026-03-15
  tasks: 3 (checkpoint-based continuation)
  files: 10
  commits: 3
---

# Phase 4 Plan 2: Settings UI & Model Guidance Summary

**One-liner:** Compact settings pane with supported-language picker, conditional model guidance, and System Settings integration

## What Was Built

Replaced the placeholder Settings screen with a real compact native pane showing a target-language picker populated from Apple's supported languages. Implemented conditional model guidance that stays absent before relevance, shows generic guidance after a real missing-model event with unknown pair certainty, and can upgrade to pair-specific guidance when trusted known-pair context exists. Added runtime→settings relevance recording so missing-model outcomes from the popup flow inform Settings guidance without mutating active requests. Created SupportedLanguageOption for natural-language picker labels and TranslationModelGuidance for the conditional guidance state machine with Wave 0 test coverage.

## Tasks Completed

### Task 1: Wave 0 — lock guidance-state behavior with focused tests

**Files:**
- Created: `Transy/Settings/TranslationModelGuidance.swift`, `TransyTests/TranslationModelGuidanceTests.swift`
- Modified: `Transy/Settings/SettingsStore.swift`, `Transy.xcodeproj/project.pbxproj`

**What was done:**
- Created `TranslationModelGuidance` struct with `GuidanceState` enum (none/generic/pairSpecific)
- Added `MissingModelContext` to track missing-model relevance from runtime outcomes
- Extended `SettingsStore` with `missingModelContext` and `recordMissingModel()` method
- Implemented Wave 0 tests covering all three guidance states
- Injected `statusProvider` for testability without depending on live Apple assets
- Ensured guidance is `.none` before relevance, `.generic` after missing-model with unknown pair, and `.pairSpecific` only when trusted known-pair context exists and status is `.supported`

**Commit:** `d375fa2`

**Verification:** TranslationModelGuidanceTests passes (5 tests covering all state transitions)

### Task 2: Build the compact Settings UI, supported-language picker, and guidance action

**Files:**
- Created: `Transy/Settings/SupportedLanguageOption.swift`
- Modified: `Transy/Settings/SettingsView.swift`, `Transy/Settings/TranslationModelGuidance.swift`, `Transy/Translation/TranslationAvailabilityClient.swift`, `Transy/Popup/PopupView.swift`, `Transy/AppDelegate.swift`, `Transy/Popup/PopupController.swift`, `Transy.xcodeproj/project.pbxproj`

**What was done:**
- Created `SupportedLanguageOption` to load supported languages from Apple's API with localized display names
- Replaced placeholder `SettingsView` with real compact pane showing target-language picker
- Picker populated from `LanguageAvailability.supportedLanguages`, sorted by display name
- Added conditional guidance section that appears only when `guidanceState != .none`
- Implemented generic and pair-specific guidance variants with System Settings action
- Refined `TranslationAvailabilityClient.PreflightResult` to distinguish `.missingModel` from `.unsupported` and `.failed`
- Wired `PopupView` to record missing-model relevance into `SettingsStore` when preflight returns `.missingModel`
- Passed `settingsStore` through `AppDelegate` → `PopupController` → `PopupView` for relevance recording
- Settings pane stays compact by default, expands modestly when guidance becomes visible
- Button action opens Language & Region pane in System Settings via `x-apple.systempreferences:com.apple.Localization-Settings`

**Commit:** `fcc1f9a`

**Verification:** Full test suite passes (37 tests)

### Task 3 Continuation: Fix blank picker and improve System Settings guidance

**Files:**
- Modified: `Transy/Settings/SettingsView.swift`

**What was done:**
- Added `selectedLanguageID` @State to manage picker selection independently of stored target
- Implemented `reconcileSelectedLanguage()` with three-tier matching: exact ID → languageCode fuzzy → first-supported fallback
- Added fallback logic: if stored target not in supported list, select first supported language and update store
- Disabled picker while `supportedLanguages` is empty (during loading)
- Updated guidance copy to include explicit path: "System Settings → General → Language & Region → Translation Languages"
- Renamed button from "Open System Settings" to "Open Language & Region" for clarity
- Fixed System Settings URL scheme to use `.extension` suffix required on macOS 13+
- Added languageCode-based fuzzy matching for OS preferred languages with region codes (e.g. `en-JP` → `en`)

**Commits:** `090f763`, `3d5f3d6`, `851f3c6`

**Verification:** Full test suite passes (37 tests), build succeeds, human checkpoint approved

**Issues found and fixed (3 rounds of checkpoint feedback):**
1. Blank picker on first launch — SwiftUI couldn't match selection to any tag before async load
2. System Settings landing on wrong pane — URL scheme missing `.extension` suffix for macOS 13+
3. Arabic as default instead of English — OS locale `en-JP` didn't match supported `en`; added languageCode fuzzy match

**Resolution:**
1. Picker reconciliation with three-tier fallback ensures valid selection after async loading
2. `.extension` suffix on pane ID reliably opens Language & Region
3. languageCode-based fuzzy match correctly resolves region-qualified OS preferences

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Blank picker on first launch**
- **Found during:** Checkpoint verification round 1
- **Issue:** Picker appeared blank because binding used `settingsStore.targetLanguage.minimalIdentifier` before `supportedLanguages` loaded
- **Fix:** Added `selectedLanguageID` @State with reconciliation logic after async language loading
- **Commit:** `090f763`

**2. [Rule 2 - Bug] System Settings opened to wrong pane**
- **Found during:** Checkpoint verification round 1
- **Issue:** URL scheme missing `.extension` suffix for macOS 13+; opened to last-viewed pane
- **Fix:** Changed to `com.apple.Localization-Settings.extension` and updated guidance copy with explicit path
- **Commit:** `3d5f3d6`

**3. [Rule 1 - Bug] Arabic shown as default instead of OS preferred language**
- **Found during:** Checkpoint verification round 2
- **Issue:** OS locale `en-JP` (`minimalIdentifier` = "en-JP") did not match supported "en"; fell through to first alphabetical (Arabic)
- **Fix:** Added `languageCode`-based fuzzy match step in reconciliation before the fallback
- **Commit:** `851f3c6`

## Verification Results

✅ All plan verification criteria met:
- TranslationModelGuidanceTests passes (5 tests)
- Full test suite passes (37 tests in 11 suites)
- Build succeeds without warnings
- Picker shows valid target after language loading
- Guidance copy includes explicit System Settings path

## Key Technical Decisions

1. **Picker reconciliation:** Manage selection via separate @State to handle async language loading; reconcile stored target with supported options after load completes
2. **Fallback behavior:** If stored target not in supported list, select first supported language and update store automatically (graceful degradation)
3. **Runtime relevance recording:** Record missing-model context from `PopupView` preflight outcome without mutating active popup state
4. **Guidance state machine:** Three states (none/generic/pairSpecific) driven by `missingModelContext` and optional `LanguageAvailability.status()` check
5. **System Settings action:** Open Language & Region pane via URL scheme; rely on explicit guidance copy for Translation Languages sub-section navigation
6. **PreflightResult refinement:** Distinguish `.missingModel` (supported but not installed) from `.unsupported` (not supported) and `.failed` (other errors)

## Files Created

1. **Transy/Settings/SupportedLanguageOption.swift**
   - Loads supported languages from Apple's `LanguageAvailability.supportedLanguages`
   - Maps each language to localized display name via `Locale.current.localizedString(forIdentifier:)`
   - Sorted naturally by display name

2. **Transy/Settings/TranslationModelGuidance.swift**
   - Conditional guidance state machine (none/generic/pairSpecific)
   - Injected `statusProvider` for testability
   - Returns `.none` when model installed or pair unsupported

3. **TransyTests/TranslationModelGuidanceTests.swift**
   - Wave 0 coverage for guidance state transitions
   - Tests: no guidance before relevance, generic after missing-model with unknown pair, pair-specific when known pair is supported, no guidance when installed/unsupported

## Files Modified

1. **Transy/Settings/SettingsView.swift**
   - Replaced placeholder with real compact pane
   - Target-language picker populated from supported languages
   - Conditional guidance section (generic/pair-specific variants)
   - Picker reconciliation logic for first-launch blank fix
   - Explicit System Settings path in guidance copy

2. **Transy/Settings/SettingsStore.swift**
   - Added `missingModelContext` property
   - Added `recordMissingModel()` method for runtime relevance recording

3. **Transy/Translation/TranslationAvailabilityClient.swift**
   - Refined `PreflightResult` enum to include `.missingModel` case
   - Map `LanguageAvailability.Status.supported` to `.missingModel` (not `.ready`)

4. **Transy/Popup/PopupView.swift**
   - Accept `settingsStore` parameter
   - Record missing-model relevance when preflight returns `.missingModel`
   - No mutation of active popup state

5. **Transy/AppDelegate.swift**
   - Pass `settingsStore` to `PopupController.show()`

6. **Transy/Popup/PopupController.swift**
   - Accept and forward `settingsStore` parameter to `PopupView`

## Integration Points

- **Upstream:** Phase 4 Plan 1 provides `SettingsStore` with persistent target language
- **Downstream:** Phase 4 complete — settings window, target language selection, and model guidance all functional
- **Contracts satisfied:**
  - Settings shows compact native pane with broad language picker
  - Target language changes auto-save and persist across relaunch
  - Guidance absent before relevance, generic after missing-model with unknown pair
  - System Settings action opens Language & Region with explicit guidance path

## Next Steps

Phase 4 is complete. Next phase (if planned) would cover:
- Provider selection or external translation service integration
- Advanced settings (appearance, hotkey customization)
- Additional UX polish

## Known Limitations

- System Settings URL scheme cannot deep-link to Translation Languages sub-section within Language & Region; guidance copy compensates by providing explicit navigation path
- Picker reconciliation assumes first supported language is a reasonable fallback if stored target not supported
- Pair-specific guidance only appears when `knownSourceLanguage` is explicitly provided (not inferred from ambiguous runtime state)

---

**Status:** ✅ Checkpoint reached (awaiting manual verification)
**Duration:** TBD
**Completed:** 2026-03-15

## Self-Check: PASSED

All claims verified:
- ✓ Transy/Settings/SupportedLanguageOption.swift exists
- ✓ Transy/Settings/TranslationModelGuidance.swift exists
- ✓ TransyTests/TranslationModelGuidanceTests.swift exists
- ✓ Commit d375fa2 exists
- ✓ Commit fcc1f9a exists
- ✓ Commit 090f763 exists
- ✓ All tests pass (37 tests in 11 suites)
- ✓ Build succeeds

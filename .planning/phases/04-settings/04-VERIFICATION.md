---
phase: 04-settings
verified: 2026-03-15T15:00:00Z
status: passed
score: 8/8 must-haves verified
re_verification: false
---

# Phase 4: Settings Verification Report

**Phase Goal:** User can choose the target translation language in a dedicated settings window and is guided to download any required on-device Apple Translation models that are not yet available.
**Verified:** 2026-03-15T15:00:00Z
**Status:** ✅ PASSED
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths (from ROADMAP.md Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Opening settings from the menu bar shows a window where the user can select the target translation language | ✓ VERIFIED | `SettingsView` with Picker populated from `SupportedLanguageOption.loadSupportedLanguages()`; UAT Test 1 passed; MenuBarView → Settings scene wiring intact from Phase 1 |
| 2 | The selected target language persists across app restarts | ✓ VERIFIED | `SettingsStore` persists via UserDefaults; `SettingsStoreTests` covers persistence; UAT Test 3 passed (quit/relaunch confirmed) |
| 3 | When a required Apple Translation model for the selected language pair is not downloaded, the user sees a clear prompt guiding them to download it | ✓ VERIFIED | `TranslationModelGuidance` with `.generic`/`.pairSpecific` states; `TranslationModelGuidanceTests` covers all transitions; UAT Tests 5-7 passed; System Settings button opens Language & Region |
| 4 | The settings window does not cause the Dock icon to appear or the app to enter the regular activation policy | ✓ VERIFIED | Settings scene uses native SwiftUI `Settings` scene; LSUIElement=YES from Phase 1 preserved; UAT Test 1 passed (no Dock icon) |

**Additional truths from PLAN must_haves:**

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 5 | On first launch, Transy resolves a default target language from the OS preference and persists it | ✓ VERIFIED | `SettingsStore.init` with `preferredLanguageResolver`; `SettingsStoreTests` "First run persists OS preferred language to UserDefaults" passed; UAT Test 2 passed (English, not Arabic, after fuzzy-match fix) |
| 6 | Once a target language has been stored, later OS language changes do not overwrite that stored choice | ✓ VERIFIED | `SettingsStoreTests` "Stored target language is not overwritten by later OS preference changes" passed |
| 7 | Changing the target language affects the next translation request immediately | ✓ VERIFIED | `snapshotTargetLanguage()` in AppDelegate; UAT Test 4 passed |
| 8 | An already-visible popup/request keeps the target language snapshot it started with | ✓ VERIFIED | `TargetLanguageSnapshotTests` "Request snapshot freezes target language at capture time" passed; UAT Test 4 passed (popup did not mutate mid-flight) |

**Score: 8/8 truths verified**

---

### Required Artifacts

**Plan 01 (SettingsStore & Request Snapshot):**

| Artifact | Provides | Exists | Lines | Substantive | Wired | Status |
|----------|----------|--------|-------|-------------|-------|--------|
| `Transy/Settings/SettingsStore.swift` | Defaults-backed @Observable target-language source of truth | ✓ | 73 | ✓ (UserDefaults persistence, minimalIdentifier round-trip, snapshot method) | ✓ (owned by AppDelegate, injected to Settings scene) | ✓ VERIFIED |
| `Transy/AppDelegate.swift` | Request-time target-language snapshot wiring for popup requests | ✓ | Modified | ✓ (owns `settingsStore`, snapshots target at trigger time) | ✓ (passes frozen client to PopupController) | ✓ VERIFIED |
| `Transy/Settings/SettingsView.swift` | Settings pane with target-language picker and conditional guidance | ✓ | 141 | ✓ (real picker + SupportedLanguageOption + TranslationModelGuidance) | ✓ (injected from Settings scene) | ✓ VERIFIED |
| `Transy/TransyApp.swift` | Settings scene injection of the shared store | ✓ | Modified | ✓ (`SettingsView(settingsStore: appDelegate.settingsStore)`) | ✓ (Settings scene wired) | ✓ VERIFIED |
| `Transy/Popup/PopupController.swift` | Popup entry point that accepts frozen TranslationAvailabilityClient | ✓ | Modified | ✓ (accepts `availabilityClient` + `settingsStore` parameters) | ✓ (called from AppDelegate with frozen client) | ✓ VERIFIED |
| `TransyTests/SettingsStoreTests.swift` | Wave 0 coverage for first-run defaulting and persistence | ✓ | 48 | ✓ (2 tests: first-run persistence, stored-value-wins-over-OS-changes) | ✓ (all tests pass) | ✓ VERIFIED |
| `TransyTests/TargetLanguageSnapshotTests.swift` | Wave 0 coverage for request snapshot behavior | ✓ | 36 | ✓ (1 test: snapshot freezes target at capture time) | ✓ (test passes) | ✓ VERIFIED |

**Plan 02 (Settings UI & Model Guidance):**

| Artifact | Provides | Exists | Lines | Substantive | Wired | Status |
|----------|----------|--------|-------|-------------|-------|--------|
| `Transy/Settings/SupportedLanguageOption.swift` | Localized supported-language loader derived from LanguageAvailability.supportedLanguages | ✓ | 27 | ✓ (loads from Apple API, localized display names, sorted) | ✓ (used in SettingsView picker) | ✓ VERIFIED |
| `Transy/Settings/TranslationModelGuidance.swift` | Generic-vs-pair-specific guidance seam and System Settings action | ✓ | 68 | ✓ (GuidanceState enum, statusProvider injection, .none/.generic/.pairSpecific logic) | ✓ (used in SettingsView conditional guidance) | ✓ VERIFIED |
| `Transy/Translation/TranslationAvailabilityClient.swift` | PreflightResult that distinguishes missing-model relevance from unsupported/installed states | ✓ | Modified | ✓ (`.missingModel` case added to PreflightResult) | ✓ (returned from preflight, checked in PopupView) | ✓ VERIFIED |
| `Transy/Popup/PopupView.swift` | Runtime-to-settings missing-model relevance recording with no live popup mutation | ✓ | Modified | ✓ (calls `settingsStore.recordMissingModel` on `.missingModel` preflight result) | ✓ (receives settingsStore from PopupController) | ✓ VERIFIED |
| `TransyTests/TranslationModelGuidanceTests.swift` | Wave 0 coverage for settings guidance logic | ✓ | 101 | ✓ (5 tests covering all guidance state transitions) | ✓ (all tests pass) | ✓ VERIFIED |

---

### Key Link Verification

**Plan 01 (SettingsStore & Request Snapshot):**

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `Transy/TransyApp.swift` | `Transy/Settings/SettingsView.swift` | Settings scene injection | ✓ WIRED | `SettingsView(settingsStore: appDelegate.settingsStore)` at line 15 of TransyApp.swift |
| `Transy/AppDelegate.swift` | `Transy/Settings/SettingsStore.swift` | Request-time read of current target language | ✓ WIRED | `let targetLanguage = settingsStore.snapshotTargetLanguage()` in `handleTrigger()` |
| `Transy/AppDelegate.swift` | `Transy/Popup/PopupController.swift` | Frozen availability client passed on popup show | ✓ WIRED | `popupController.show(..., availabilityClient: ...)` with frozen client |

**Plan 02 (Settings UI & Model Guidance):**

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `Transy/Settings/SettingsView.swift` | `Transy/Settings/SettingsStore.swift` | Picker binding / immediate auto-save | ✓ WIRED | `.onChange(of: selectedLanguageID)` → `settingsStore.updateTargetLanguage(option.language)` at line 26-29 |
| `Transy/Popup/PopupView.swift` | `Transy/Settings/SettingsStore.swift` | Record missing-model relevance from real runtime outcomes | ✓ WIRED | `settingsStore.recordMissingModel(targetLanguage:knownSourceLanguage:)` at line 91-95 when preflight returns `.missingModel` |
| `Transy/Settings/SupportedLanguageOption.swift` | `Translation.LanguageAvailability` | Supported target-language load | ✓ WIRED | `await availability.supportedLanguages` at line 21 |
| `Transy/Settings/TranslationModelGuidance.swift` | `Transy/Settings/SettingsStore.swift` | Derive none vs generic vs pair-specific guidance from stored relevance context | ✓ WIRED | `init(missingModelContext: MissingModelContext?)` receives `settingsStore.missingModelContext` |
| `Transy/Translation/TranslationAvailabilityClient.swift` | `Transy/Popup/PopupView.swift` | Precise preflight outcome distinguishes missing-model relevance from unrelated failures | ✓ WIRED | `PreflightResult.missingModel` case; `switch result` at PopupView handles `.missingModel` |
| `Transy/Settings/TranslationModelGuidance.swift` | `Translation.LanguageAvailability` | Optional known-pair status check when trusted source context exists | ✓ WIRED | `try await provider(knownSource, context.targetLanguage)` at line 34 |
| `Transy/Settings/TranslationModelGuidance.swift` | System Settings | Single guidance action | ✓ WIRED | `NSWorkspace.shared.open(url)` with `x-apple.systempreferences:com.apple.Localization-Settings.extension` at line 138 of SettingsView |

---

### Requirements Coverage

| Requirement | Source Plan(s) | Description | Status | Evidence |
|-------------|---------------|-------------|--------|----------|
| **APP-02** | 04-01, 04-02 | User can choose the target translation language in a settings window | ✓ SATISFIED | SettingsView with Picker populated from Apple's supported languages; auto-save on selection change; persistence via SettingsStore; UAT Tests 1-4 passed; human checkpoint approved after 3 rounds of fixes (blank picker, System Settings link, Arabic default) |
| **APP-03** | 04-02 | User is guided to download any Apple translation models required for the selected language pair when they are not yet available on the device | ✓ SATISFIED | TranslationModelGuidance with conditional .none/.generic/.pairSpecific states; runtime recording of missing-model outcomes from PopupView preflight; System Settings button opens Language & Region; UAT Tests 5-7 passed; human checkpoint approved |

**No orphaned requirements.** REQUIREMENTS.md maps only APP-02 and APP-03 to Phase 4, and both plans claim them.

---

### Test Results

```
✔ Test "First run persists OS preferred language to UserDefaults" passed
✔ Test "Stored target language is not overwritten by later OS preference changes" passed
✔ Suite SettingsStoreTests passed

✔ Test "Request snapshot freezes target language at capture time" passed
✔ Suite TargetLanguageSnapshotTests passed

✔ Test "Guidance is none before any missing-model-relevant runtime state exists" passed
✔ Test "Guidance is generic after a missing-model event with unknown pair certainty" passed
✔ Test "Guidance is pair-specific when trusted source context exists and status is supported" passed
✔ Test "Guidance is none when status is installed" passed
✔ Test "Guidance is none when status is unsupported" passed
✔ Suite "TranslationModelGuidance Tests" passed

✔ Test run with 37 tests in 11 suites passed. BUILD SUCCEEDED.
```

---

### Anti-Patterns Found

None. No TODOs, FIXMEs, placeholders, empty returns, or stub implementations detected in any of the 4 Settings source files or 3 test files.

**Notable implementation improvements:**
1. **Picker reconciliation logic** — Three-tier matching (exact ID → languageCode fuzzy → first-supported fallback) ensures valid selection after async language loading and handles OS locales with region codes (e.g. `en-JP` → `en`)
2. **System Settings URL scheme** — Uses `.extension` suffix (`com.apple.Localization-Settings.extension`) required on macOS 13+ (Ventura and later) to reliably open Language & Region pane
3. **Guidance copy** — Includes explicit navigation path ("System Settings → General → Language & Region → Translation Languages") to compensate for lack of deep-link to Translation Languages sub-section

---

### Deviation Tracking

Three deviations occurred during Plan 02 execution, all caught during the blocking human checkpoint and auto-fixed before approval:

| Round | Deviation | Fix | Commits | Impact |
|-------|-----------|-----|---------|--------|
| 1 | **[Rule 1 - Bug]** Blank picker on first launch; SwiftUI couldn't match selection before async load | Added `selectedLanguageID` @State with reconciliation logic after language loading | `090f763` | Essential UX fix; picker now shows valid selection immediately |
| 2 | **[Rule 2 - Bug]** System Settings opened to wrong pane; URL scheme missing `.extension` suffix for macOS 13+ | Changed URL to `com.apple.Localization-Settings.extension` and updated guidance copy with explicit path | `3d5f3d6` | Essential UX fix; System Settings now opens to correct pane |
| 3 | **[Rule 1 - Bug]** Arabic shown as default instead of OS preferred language (English); OS locale `en-JP` did not match supported `en` | Added languageCode-based fuzzy match step in reconciliation before fallback | `851f3c6` | Essential first-run UX fix; correctly resolves region-qualified OS preferences |

All three deviations were identified during the Plan 02 Task 3 blocking human checkpoint, fixed in response to explicit user feedback, and verified before plan approval. The checkpoint-based continuation pattern worked as designed.

---

### Human Verification Completed

Per 04-UAT.md, all 8 tests passed:

1. **Settings Window Surfacing** — Single native Settings window appears; no Dock icon; no duplicate windows ✅
2. **Target Language Picker Default** — On first launch, picker shows OS preferred language (English) pre-selected — not blank, not Arabic ✅
3. **Language Selection & Persistence** — Choose Japanese, quit/relaunch, picker still shows Japanese ✅
4. **Request Snapshot Isolation** — Change target while popup visible; visible popup does NOT change; next trigger uses new target ✅
5. **No Guidance Before Relevance** — Fresh state shows only picker, no guidance section ✅
6. **Generic Guidance After Missing Model** — Trigger missing-model error, reopen Settings, guidance section appears with System Settings path ✅
7. **System Settings Deep Link** — Click "Open Language & Region", System Settings opens to Language & Region pane (not last-viewed pane) ✅
8. **Compact Layout** — Settings compact by default (just picker); grows modestly when guidance appears ✅

**Total: 8 passed, 0 issues, 0 pending**

---

## Summary

Phase 4 goal is **fully achieved**. All four ROADMAP success criteria are satisfied:

1. **Settings window with target language picker** — `SettingsView` with Picker populated from Apple's supported languages using natural-language names, sorted alphabetically. Settings scene injection from Phase 1 preserved. UAT Test 1 passed.

2. **Target language persistence across restarts** — `SettingsStore` persists via UserDefaults using `minimalIdentifier`; reconstructs `Locale.Language` on read; resolves default from OS preferred language on first run only; stored value wins over later OS changes. UAT Test 3 passed.

3. **Model download guidance** — `TranslationModelGuidance` with three states: `.none` (before relevance), `.generic` (after missing-model with unknown pair), `.pairSpecific` (when known pair is supported but not installed). Runtime recording from `PopupView` preflight outcome. System Settings button opens Language & Region with explicit navigation path. UAT Tests 5-7 passed.

4. **No Dock/activation regression** — Settings window uses native SwiftUI `Settings` scene; `LSUIElement=YES` from Phase 1 intact; no `.accessory` policy change. UAT Test 1 passed.

**Additional must-haves from PLAN frontmatter:**
- ✅ First-run default resolution from OS preference (+ fuzzy match for region codes)
- ✅ Stored target wins over later OS changes
- ✅ Request snapshot freezes target at trigger time
- ✅ Active popup stays stable while next request picks up new target

**Test coverage:** 37 tests in 11 suites, all green. Wave 0 tests lock first-run defaulting (SettingsStoreTests), request snapshot behavior (TargetLanguageSnapshotTests), and guidance state machine (TranslationModelGuidanceTests).

**Checkpoint-based continuation:** Plan 02 Task 3 was a blocking human-verify checkpoint. Three bugs were found (blank picker, wrong System Settings pane, incorrect first-run default) and fixed across 3 rounds of feedback before approval. The checkpoint pattern ensured UX quality before phase completion.

**Phase 4 is complete.** All v1 requirements (APP-01, APP-02, APP-03, TRIG-01/02/03, POP-01/02/03, TRAN-01/02/03) are now satisfied. The core reading-flow loop is fully functional and configurable.

---

_Verified: 2026-03-15T15:00:00Z_
_Verifier: Claude (gsd-verifier)_

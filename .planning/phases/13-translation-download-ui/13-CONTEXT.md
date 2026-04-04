# Phase 13: Translation Download UI - Context

**Gathered:** 2026-04-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Replace the manual "Open Language & Region" model-download guidance with the Translation framework's built-in automatic download prompt. When a required translation model is missing, `session.translate()` handles it — no manual intervention or System Settings navigation needed.

</domain>

<decisions>
## Implementation Decisions

### Download Prompt Behavior
- **D-01:** Remove the `.missingModel` short-circuit in `LoadingPopupText.translationAction()`. Instead of calling `preflight()` and erroring on `.missingModel`, let `session.translate()` proceed directly. The Translation framework automatically prompts the user for download permission when the model is missing but supported.
- **D-02:** The `TranslationAvailabilityClient.preflight()` method's `.missingModel` case should no longer trigger an error popup. The preflight check itself may be simplified or removed since the framework handles missing models natively.

### Settings Guidance Removal
- **D-03:** Delete `TranslationModelGuidance.swift` and `MissingModelContext` struct entirely. These are no longer needed when the framework handles downloads.
- **D-04:** Remove the guidance UI section from `GeneralSettingsView.swift` — the `TranslationModelGuidance.GuidanceState` enum, the conditional guidance VStack with "Translation Model Required" text, the "Open Language & Region" button, and the `openSystemSettings()` helper.
- **D-05:** Remove `missingModelContext` property from `SettingsStore` and `recordMissingModel()` method. No runtime state tracking for missing models needed.

### Folded Todos
- **D-06:** "Add translation model install guidance" — Resolved by this phase. Framework's built-in download UI replaces any custom guidance.
- **D-07:** "Track translation cancellation latency" — Include investigation of cancellation latency in re-trigger/dismiss flows. Note: `TranslationSession.cancel()` is only available on macOS 26+; macOS 15 must rely on configuration invalidation.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Apple Translation Framework
- Apple documentation: "Translating text within your app" — confirms `.translationTask()` + `session.translate()` automatically prompts for model download when needed
- `_Translation_SwiftUI.swiftinterface` — `translationTask(_:action:)`, `translationPresentation(isPresented:text:...)` API signatures
- `Translation.swiftinterface` — `prepareTranslation()`, `translate(_:)`, `LanguageAvailability.Status` (.installed, .supported, .unsupported)

### Project Files
- `.planning/REQUIREMENTS.md` — TDL-01 requirement
- `.planning/ROADMAP.md` — Phase 13 goal and success criteria

</canonical_refs>

<code_context>
## Existing Code Insights

### Key Files to Modify
- `Transy/Popup/PopupView.swift` (lines 148-170) — `LoadingPopupText.translationAction()` contains the `.missingModel` short-circuit that must be removed
- `Transy/Translation/TranslationAvailabilityClient.swift` — `.missingModel` case in `PreflightResult` enum; may simplify or remove preflight entirely
- `Transy/Settings/GeneralSettingsView.swift` (lines 48-94) — Guidance UI section to delete; also lines 109-124 for guidance state management
- `Transy/Settings/SettingsStore.swift` — `missingModelContext` property and `recordMissingModel()` to remove

### Files to Delete
- `Transy/Settings/TranslationModelGuidance.swift` — Entire file (TranslationModelGuidance struct + MissingModelContext struct)

### Test Files Affected
- `TransyTests/TranslationModelGuidanceTests.swift` (if exists) — Delete
- `TransyTests/TranslationAvailabilityClientTests.swift` (if exists) — Update to remove `.missingModel` test cases

### Established Patterns
- `.translationTask(translationConfiguration, action:)` modifier already used on `LoadingPopupText`
- `TranslationSession.Configuration` with `invalidate()` pattern for re-triggering translations
- Swift Testing framework (`@Suite`, `@Test`, `#expect`) for unit tests

### Integration Points
- `PopupView` → `LoadingPopupText` → `.translationTask()` action — main translation flow
- `SettingsStore` — remove `missingModelContext` / `recordMissingModel()`
- `GeneralSettingsView` — remove guidance section, simplify `.onChange(of: settingsStore.missingModelContext)`

</code_context>

<specifics>
## Specific Ideas

- The Apple documentation explicitly states: "With the customizable translation APIs, the framework asks a person for permission to download the language translation models, if necessary." This confirms the approach.
- `prepareTranslation()` exists for pre-downloading models but is not needed for this phase's scope.
- `TranslationSession.cancel()` is macOS 26+ only — cancellation latency investigation should note this constraint.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 13-translation-download-ui*
*Context gathered: 2026-04-04*

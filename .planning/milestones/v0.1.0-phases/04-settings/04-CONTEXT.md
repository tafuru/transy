# Phase 4: Settings - Context

**Gathered:** 2026-03-15
**Status:** Ready for planning

<domain>
## Phase Boundary

Turn the placeholder `Settings…` entry into a real, native-feeling settings window where the user can choose a persistent target translation language and get quiet guidance when required Apple Translation models are missing. Phase 4 covers settings presentation, target-language persistence/defaulting, and model-guidance behavior. It does not expand into provider switching, popup redesign, or broader translation-management UX.

</domain>

<decisions>
## Implementation Decisions

### Settings Window Information Density
- Keep Phase 4 settings as a single compact pane rather than a sidebar or multi-page preferences UI.
- Keep the surface controls-first with only minimal supporting copy.
- Show model guidance in the same pane only when it is relevant, rather than reserving permanent space for it.
- Let the window stay compact by default and grow slightly only when guidance becomes visible.

### Target Language Picker Presentation
- Show a broad set of supported target-language choices rather than a tiny curated shortlist.
- Use a standard native picker / menu presentation instead of a custom searchable or recents-driven UI.
- Display natural language names only; do not include language codes or dual-name formatting.
- Initialize the Phase 4 default from the OS preferred language rather than preserving the temporary fixed-English default from Phase 3.

### Model Guidance Behavior
- Missing-model messaging in Settings should stay short and matter-of-fact, but it should still make the next action obvious.
- Provide one clear action that guides the user to the relevant System Settings path for Apple Translation models.
- When the app can confidently determine that the required model for a known source/target pair is missing, show that guidance immediately in Settings.
- When the pair is not yet known (for example, initial settings before any translation context exists), show only generic guidance in Settings; after a real translation reveals `Translation model not installed.`, Settings can later surface pair-specific guidance.

### Settings Change Propagation
- Persist target-language changes automatically; no explicit Save / Apply button is needed.
- A new selection should affect the next translation request immediately.
- An in-flight or already visible popup should not mutate mid-request; it keeps the language/configuration it started with.
- Once Transy has stored a chosen target language, later OS preferred-language changes should not auto-overwrite that stored choice.

### Claude's Discretion
- Exact section headers, spacing, and row ordering inside the single-pane settings window.
- Exact wording of the generic and pair-specific guidance copy, as long as it stays short, quiet, and action-oriented.
- Exact compact/expanded window dimensions as long as the default view stays small and the guidance state only grows modestly.
- Exact mechanism for remembering enough recent translation context to surface pair-specific guidance later, as long as generic guidance is used whenever pair certainty is unavailable.

</decisions>

<specifics>
## Specific Ideas

- The desired Phase 4 feel is still quiet/native, not a heavy “setup wizard” or dashboard.
- The Phase 3 fixed-English target was only a bridge until settings existed; the Phase 4 UX should feel like a real language preference, not a temporary workaround.
- A natural user flow is: open Settings, choose target language, let the app auto-save, and have the next translation use that choice. If a later real translation reveals a missing model, reopening Settings should present a concrete Apple Settings action without making the popup itself verbose.

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Transy/MenuBar/MenuBarView.swift`: already exposes the stable `Settings…` entry and uses `NSApp.activate()` before `openSettings()`.
- `Transy/TransyApp.swift`: already defines the app’s SwiftUI `Settings` scene and routes it to `SettingsView()`.
- `Transy/Settings/SettingsView.swift`: current placeholder can be replaced in place with the real Phase 4 UI.
- `Transy/AppState.swift`: already carries a reserved comment for a future `targetLanguage` setting and remains the natural shared-state entry point.
- `Transy/Translation/TranslationAvailabilityClient.swift`: already centralizes target-language handling plus Apple `LanguageAvailability` preflight outcomes.
- `Transy/Popup/PopupView.swift` and `Transy/Translation/TranslationErrorMapper.swift`: already keep runtime popup failure copy short, so Settings guidance can stay complementary rather than duplicating popup UI.

### Established Patterns
- Transy should remain quiet, compact, and native-feeling because it is an `LSUIElement` menu bar utility.
- The settings entry is already expected to open a real native Settings window, not a custom app window.
- Popup UX should remain focused on the translation result/error itself; heavier explanation belongs in Settings.
- `project.yml` remains the source of truth for Xcode project configuration.

### Integration Points
- The real `SettingsView` should plug into the existing `Settings` scene rather than inventing a second settings surface.
- The chosen target language must eventually replace the current fixed-English path used by `TranslationAvailabilityClient` / `PopupView`.
- Model guidance needs to complement Phase 3’s terse popup error path: generic guidance is available from initial settings, while pair-specific guidance becomes possible after real availability context exists.
- The settings store must persist independently of any currently displayed popup so that active translations stay stable while future requests pick up the new language.

</code_context>

<deferred>
## Deferred Ideas

- Searchable language selection, recent languages, or favorites remain out of scope for Phase 4.
- Any provider selection, unsupported-pair fallback, or external translation-provider work stays in later phases.
- Mid-flight mutation of a currently visible popup after a settings change is intentionally deferred; Phase 4 only requires the next request to use the new configuration.
- Any attempt to download or manage Apple translation assets directly in-app remains out of scope; guidance should point to Apple’s System Settings flow.

</deferred>

---

*Phase: 04-settings*
*Context gathered: 2026-03-15*

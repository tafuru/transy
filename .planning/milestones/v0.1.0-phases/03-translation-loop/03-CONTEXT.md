# Phase 3: Translation Loop - Context

**Gathered:** 2026-03-14
**Status:** Ready for planning

<domain>
## Phase Boundary

Resolve the existing muted source-text popup into a real on-device translation using Apple's Translation framework. Phase 3 covers automatic source-language detection, success/error delivery inside the existing popup, and race-safe request handling. Target-language settings, model-management UI, and broader popup redesign remain separate phases.

</domain>

<decisions>
## Implementation Decisions

### Default Target Language
- Phase 3 uses a fixed default target language of English until Phase 4 settings exist.
- Treat that default as generic English rather than a region-specific variant.
- Do not add extra in-app messaging about the temporary English default; README / PR communication is enough for now.
- If the source text is already English, it is acceptable for the resulting output to still be English rather than showing a special same-language message.

### Failure Presentation
- If translation fails, keep the popup open and show a short inline error message instead of dismissing silently.
- For missing-model / unavailable-pair cases, the message should be slightly explicit rather than fully generic.
- Error state remains visible until the user dismisses the popup with `Escape` or outside click.
- Error copy should stay short and matter-of-fact rather than verbose or instructional.

### Loading Presentation
- Keep the current muted source-text loading treatment in Phase 3; do not add shimmer, spinner, or ellipsis.
- If translation takes longer than expected, keep the same quiet loading appearance rather than escalating the visual treatment.
- Keep the popup compact during loading; long source text should still favor truncation over aggressive expansion.
- When translation completes, replace the loading state almost instantly rather than using a noticeable transition animation.

### Re-trigger and Cancellation Behavior
- If the user triggers translation again while a request is in flight, prioritize the new selection and cancel the older request.
- Reuse the same popup and swap immediately to the newly captured source text while the replacement translation starts.
- If the popup is dismissed while translation is in flight, cancel the in-progress request immediately.
- Any stale result that arrives from an older or cancelled request must be ignored and must never overwrite the currently active request.

### Claude's Discretion
- Exact wording of the non-model error copy as long as it stays short and matter-of-fact.
- Exact state-model shape (`enum`, view model, coordinator object) used to drive loading / result / error transitions.
- Exact cancellation/token mechanism used to prevent stale results from rendering.
- Exact source-text normalization rules before sending text into the Translation framework.

</decisions>

<specifics>
## Specific Ideas

- The user was curious about eventually trying a skeleton / gradient loading treatment, but chose to keep the current muted source-text presentation for Phase 3.
- The near-term workflow remains optimized for Japanese/English reading, and a fixed English target is acceptable until Settings arrive.

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Transy/AppDelegate.swift`: `handleTrigger(preSnapshot:)` is the natural point to kick off translation immediately after the popup is shown.
- `Transy/Popup/PopupController.swift`: already manages the single popup instance, re-trigger reuse, and dismissal callbacks needed for cancellation.
- `Transy/Popup/PopupView.swift`: already renders the muted source-text placeholder and is the natural surface for loading/result/error state.
- `Transy/AppState.swift`: already centralizes popup visibility and has reserved comments for future translation state.
- `Transy/Trigger/ClipboardRestoreSession.swift`: already preserves the original clipboard snapshot across popup re-triggers and should stay orthogonal to translation logic.

### Established Patterns
- Transy is an `LSUIElement` menu bar app and should remain quiet, ambient, and non-focus-stealing.
- Phase 2 already locked the popup as compact, content-first, and reused in place rather than stacking multiple windows.
- Permission guidance and trigger monitoring are already solved and should not be reworked during Phase 3.
- `project.yml` remains the source of truth for `Transy.xcodeproj`.

### Integration Points
- Translation should begin from the existing trigger flow rather than introducing a separate launch path.
- Popup dismissal must connect to translation cancellation so hidden windows do not continue mutating visible state.
- Result/error updates should flow through the existing popup rather than creating a second surface.
- `SettingsView` remains a placeholder in Phase 3; target-language configuration UI and model-management affordances stay deferred to Phase 4.

</code_context>

<deferred>
## Deferred Ideas

- Animated skeleton / shimmer loading remains a later UI refinement if the quiet muted treatment feels too subtle.
- Target-language selection and persistence belong to Phase 4.
- User guidance for downloading or managing translation models belongs to Phase 4's settings/model-management work.
- Any special-case UX for "source is already English" is deferred; same-language output is acceptable in Phase 3.

</deferred>

---

*Phase: 03-translation-loop*
*Context gathered: 2026-03-14*

# Phase 16: Pivot Translation — Context

**Gathered:** 2026-04-17
**Status:** Ready for planning

<domain>
## Phase Boundary

When Apple Translation reports an unsupported language pair (e.g. JP→DE), the app silently chains two translations through English (source→EN→target) so the user still gets a result. The shimmer animation plays continuously across both pivot legs — the popup never flickers or shows a partial state between legs. If the pivot path also fails, a clear error message is displayed.

</domain>

<decisions>
## Implementation Decisions

### Pivot Architecture
- **D-01:** Two separate `.translationTask()` modifiers on `LoadingPopupText` — one for the primary translation, one for the pivot (EN→target) leg. Each has its own `@State var` configuration. The pivot modifier activates only when `pivotConfiguration` is non-nil.
- **D-02:** Pivot leg 2 configuration MUST use `source: Locale.Language(identifier: "en")` explicitly — NOT `source: nil` (auto-detect). Short/ambiguous intermediate English text may be misidentified with auto-detect.
- **D-03:** Pivot state (`@State var pivotConfiguration`) lives inside `LoadingPopupText` so `.id(requestID)` teardown destroys it on new clipboard events (Pitfall 7).
- **D-04:** Never call `onResult` between pivot legs. Only call `onResult` once, after leg 2 produces the final translated text (Pitfall 6).

### Pivot Detection (Error-Driven)
- **D-05:** Intercept `TranslationError.unsupportedLanguagePairing`, `.unsupportedSourceLanguage`, and `.unsupportedTargetLanguage` in the catch block BEFORE the generic `TranslationErrorMapper` handler. These errors trigger the pivot path instead of displaying an error message (Pitfall 1).
- **D-06:** No preflight `LanguageAvailability.status()` check — error-driven detection only (consistent with v0.4.0 decision to remove preflight).

### Pivot + Chunked Interaction
- **D-07:** Detect-once-then-pivot-all strategy. The first chunk is translated via the normal path. If it throws `unsupportedLanguagePairing`, ALL remaining chunks are routed through the pivot path (source→EN→target) without individual detection.
- **D-08:** If the first chunk fails with `unableToIdentifyLanguage` (e.g. chunk starts with bullet/symbol), retry with the next chunk (up to 3 chunks max). If all 3 fail language detection, display the existing error message.

### Relay Language
- **D-09:** English fixed as the relay language. No user-configurable relay. English covers the most language pairs in Apple Translation.

### Error Handling (PIV-03)
- **D-10:** When pivot also fails (EN→target unsupported), display the existing `TranslationErrorMapper.unsupportedLanguagePair` message ("This language pair isn't supported."). No mention of pivot internals to the user.
- **D-11:** Consistent with REQUIREMENTS.md Out of Scope: no "Translating via English…" progress label.

### Shimmer Continuity (PIV-02)
- **D-12:** Shimmer stays active across both pivot legs. Since `onResult` is only called after leg 2 completes, the shimmer naturally continues until the final result appears — no code changes to shimmer logic needed.

### Agent's Discretion
- Exact refactoring structure of `translationAction` to accommodate pivot branching
- Whether to extract pivot logic into a separate helper or keep inline
- Test structure and mock strategy for pivot scenarios

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Pivot Translation Architecture
- `.planning/research/PITFALLS.md` — Pitfalls 1, 2, 6, 7, 12 directly affect pivot implementation
- `.planning/research/ARCHITECTURE.md` — Two-session pivot pattern, batch API usage
- `.planning/REQUIREMENTS.md` — PIV-01, PIV-02, PIV-03 definitions and Out of Scope items

### Integration Points
- `Transy/Popup/PopupView.swift` — `LoadingPopupText`, `translationAction`, `.translationTask()` modifiers (primary integration target)
- `Transy/Translation/TranslationErrorMapper.swift` — Error interception point; pivot must catch `unsupportedLanguagePairing` before this mapper
- `Transy/Translation/TextChunker.swift` — Chunked segments fed into pivot-aware translation path

### Prior Phase Context
- `.planning/phases/15-chunked-translation/15-CONTEXT.md` — Batch API choice, separator recording, chunk architecture
- `.planning/phases/14-shimmer-animation/14-CONTEXT.md` — Shimmer overlay approach, zero-layout-impact constraint

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `TranslationErrorMapper` — Already maps `unsupportedLanguagePairing`; needs catch-block restructuring to intercept before error display
- `TextChunker.chunk(text:)` — Returns `[ChunkedSegment]` with separator recording; pivot must work with this structure
- `nextTranslationConfiguration()` — Configuration factory; pivot leg 2 needs a similar factory with explicit `source: en`

### Established Patterns
- `.translationTask(configuration, action:)` modifier pattern — pivot adds a second instance
- `@State var translationConfiguration` — pivot adds `@State var pivotConfiguration`
- Error-driven detection (no preflight) — pivot continues this pattern
- `nonisolated static func translationAction(...)` — pivot logic extends this function

### Integration Points
- `LoadingPopupText.body` — Add second `.translationTask()` modifier for pivot leg
- `translationAction` catch block — Split to intercept unsupported pair errors before generic handler
- `finishIfStillActive` / `failIfStillActive` — No changes needed; requestID guard already handles stale pivot results

</code_context>

<specifics>
## Specific Ideas

- User wants detect-once strategy with up to 3 retries for language detection failure on initial chunks
- User explicitly chose to NOT expose pivot internals to the user (no progress label, no different error message)
- Pivot failure uses the same error message as direct unsupported pair — transparent to user

</specifics>

<deferred>
## Deferred Ideas

- Error message localization — belongs in a future UI polish phase
- Configurable relay language (non-English) — revisit if user demand arises
- Translation Model Routing & Popup Dismiss (system UI dismisses NSPanel) — next milestone, separate concern

### Reviewed Todos (not folded)
- **Translation Model Routing & Popup Dismiss** — Deferred; system UI dismiss issue and model routing are separate from pivot logic. Target: next milestone after v0.5.0.

</deferred>

---

*Phase: 16-pivot-translation*
*Context gathered: 2026-04-17*

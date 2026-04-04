# Feature Research

**Domain:** macOS menu-bar translation app — v0.5.0 Translation Quality milestone
**Researched:** 2026-04-06
**Confidence:** HIGH for UX behavior and edge cases (derived from codebase analysis + Apple Translation framework constraints); MEDIUM for exact Apple Translation batch API surface (verified from framework usage patterns, not live docs)

---

## Context: What Already Exists

These features build on top of a shipped v0.4.0 foundation. Key architectural anchors:

- **`TranslationCoordinator.PopupState`**: `.hidden` → `.loading(requestID, sourceText)` → `.result` / `.error`
- **`LoadingPopupText`**: SwiftUI view that owns `@State var translationConfiguration: TranslationSession.Configuration?` and fires `.translationTask(translationConfiguration, action:)` — the Apple Translation session lifecycle is view-scoped
- **`PopupView`**: switches on `popupState`; `.loading` case renders `LoadingPopupText`; `.result`/`.error` render `PopupText`
- **`PopupText`**: renders a scrollable text block inside `.regularMaterial` rounded rect; max 640×200 pt; `isMuted: true` shows `.secondary` color (current loading placeholder)
- **`PopupController`**: tears down and recreates the SwiftUI hosting tree on each show — this cancels any in-flight `.translationTask`
- **`TranslationErrorMapper`**: maps `TranslationError.unsupportedLanguagePairing`, `.unsupportedSourceLanguage`, `.unsupportedTargetLanguage` to the user-facing string "This language pair isn't supported."

---

## Feature Landscape

### Table Stakes for v0.5.0 (Must Deliver)

The three features in scope. All are **required** — they define the milestone.

| Feature | Why Required | Complexity | Notes |
|---------|--------------|------------|-------|
| English pivot translation | Unsupported pairs (JP→DE, ZH→FR, etc.) currently show an error. This is a hard UX failure — the user gets nothing. Pivot is the fix. | MEDIUM | Two-session problem: needs two sequential `.translationTask` invocations; see Architecture section |
| Shimmer/skeleton animation | Currently loading shows static muted source text — acceptable but unpolished. Shimmer signals "work in progress" more clearly and aligns with macOS skeleton loading conventions. | LOW | Pure SwiftUI animation added to `LoadingPopupText`; no state machine changes needed |
| Chunked translation | Apple Translation may degrade on long inputs; long source text also fills the 200pt-height popup leaving no room for the result. Chunking improves both translation quality and display appropriateness. | MEDIUM | Requires text splitting logic + batch or sequential translation within a single session |

### Differentiators

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Transparent pivot (no user action) | User copies JP text with DE target → gets German result with no error, no reconfiguration. Competitors that expose "via English" intermediate as an error are worse UX. | LOW (UX) | Pivot should be invisible; a subtle "(via English)" footnote is optional polish, not required |
| Sentence-boundary chunking | Splitting at 。！？.!? and \n\n preserves translation coherence. Naive character-count splits produce fragments that degrade quality. | LOW (delta) | The split logic is the differentiator vs a naïve substr() approach |
| Shimmer that preserves source text | Shimmer overlays the muted source text (not blank placeholder bars) — user can read context during wait. This is already the v0.4.0 philosophy; shimmer enhances rather than replaces it. | LOW | Key constraint: shimmer must not obscure the source text content |

### Anti-Features (Do Not Build)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Show "Translating via English…" progress label | Transparency about pivot internals | Adds UI complexity; reveals implementation detail that users don't need; makes failure surface more visible without benefit | Silent pivot; show result; only surface error if both legs fail |
| Parallel chunk translation with Task groups | "Faster if chunks run concurrently" | Apple Translation sessions are view-scoped resources managed by `.translationTask`; concurrent sessions require multiple view attachments and state coordination that dramatically increases complexity. Batch API (`session.translations(from:)`) achieves the same in one call with correct ordering. | Use batch API (`session.translations(from:)`) or sequential loop — same speed, far simpler |
| Per-chunk error recovery | "If chunk 3 fails, retry just that chunk" | Adds retry state machine per chunk; complicates join logic; the failure modes are either the pair is unsupported (all chunks fail) or transient (retry the whole request). Per-chunk retry is over-engineering. | Fail the whole translation and let the user retry by re-copying |
| Configurable chunk size in Settings | Power-user control over 200-char threshold | The 200-char default is based on the popup height constraint and framework sweet spot. Users don't think in "translation chunk sizes." | Hard-code 200 internally; tune based on real-world testing |
| Animated progress for pivot phases | "Show leg 1 / leg 2 progress" | Pivot is fast (two on-device inferences); adding phase indicators introduces UI complexity that's visible only for ~300ms. | One shimmer, one result. Done. |

---

## Per-Feature UX Behavior and Edge Cases

### Feature 1: English Pivot Translation

#### Expected User-Facing Behavior

```
User copies: "今日はとても良い天気です" with target = German
↓
Popup opens immediately (loading state, shimmer)
↓
Behind the scenes: JP→DE attempt → TranslationError.unsupportedLanguagePairing
↓
Pivot leg 1: JP→EN → "The weather is very nice today."
↓
Pivot leg 2: EN→DE → "Das Wetter ist heute sehr schön."
↓
Popup shows: "Das Wetter ist heute sehr schön."
```

No error. No intermediate English result shown. Total latency ~2× single translation.

#### Edge Cases

| Scenario | Expected Behavior | Implementation Note |
|----------|------------------|---------------------|
| Target language IS English (source→EN) | Direct translation, no pivot attempt | Pivot only if target ≠ English AND direct fails with unsupportedLanguagePairing |
| Source language is auto-detected as English | Direct EN→target translation works; pivot shouldn't trigger | Pivot is only triggered by `unsupportedLanguagePairing` error, not by source language identity |
| Both source and target are English | Shouldn't occur in normal use; if it does, direct translation handles it (Apple passes it through or returns identity) | No pivot needed |
| Pivot leg 1 (source→EN) fails | Show `TranslationErrorMapper` message for leg-1 error (language detection failure or unsupported source) | Don't attempt leg 2 |
| Pivot leg 2 (EN→target) fails | Show error ("This language pair isn't supported.") — EN→target should always work if target is a supported language | Indicates target language itself is not supported; surface error |
| User copies new text during pivot | Race guard (`requestID` check in `finishIfStillActive` / `failIfStillActive`) discards stale pivot results | Existing race guard in `PopupView` already handles this via `translationCoordinator.activeRequestID` check |
| Source pair is supported directly (e.g., JP→EN) | No pivot — direct translation succeeds | Pivot is never attempted; the `unsupportedLanguagePairing` error is the gate |
| Unsupported source language (e.g., obscure script Apple doesn't support) | Leg 1 fails; show "Couldn't detect the source language." or "This language pair isn't supported." as appropriate | `TranslationErrorMapper` handles this from leg-1 error |

#### Architecture Constraint (CRITICAL)

Apple's `TranslationSession` is **view-scoped** — created by the `.translationTask` modifier, not instantiable directly. Pivot requires two sessions with different configurations:
- Leg 1: `source=nil` (auto-detect), `target=.english`
- Leg 2: `source=.english`, `target=userTargetLanguage`

**Implication:** `LoadingPopupText` needs a **second** `@State var pivotConfiguration: TranslationSession.Configuration?` and a **second** `.translationTask(pivotConfiguration, pivotAction:)` modifier. The two legs coordinate via `@State` — leg 1 stores its English result and sets `pivotConfiguration` to trigger leg 2.

This is a **medium-complexity** view change, not a simple closure modification. The state machine inside `LoadingPopupText` grows from 1 configuration to 2.

---

### Feature 2: Shimmer/Skeleton Animation

#### Expected User-Facing Behavior

```
User copies text
↓
Popup opens with source text visible (muted/secondary color, as today)
↓
Animated diagonal shimmer sweeps across the text continuously
↓
Translation arrives → shimmer stops → text swaps to translated result (primary color)
```

The shimmer is an overlay animation — the source text remains **readable** underneath. It is not blank placeholder bars. This is the defining constraint: Transy's loading state preserves reading context.

#### UX Behavior Details

- **Shimmer direction:** horizontal left-to-right sweep is standard; diagonal (left-to-right + slight upward) is subtler and more premium
- **Shimmer speed:** ~1.5–2 seconds per cycle (too fast = anxiety, too slow = looks frozen)
- **Shimmer opacity:** ~0.3–0.4 max alpha on the highlight. Subtle. Does not obscure text.
- **Shimmer colors:** a `LinearGradient` from `.clear` → `white.opacity(0.35)` → `.clear` on the `mask` layer; adapts to light/dark mode without explicit color checks
- **Animation repeat:** `.repeatForever(autoreverses: false)` — one-directional sweep, not back-and-forth
- **Shimmer starts:** immediately when `LoadingPopupText` appears (`.onAppear` or `initial: true` on the `onChange`)
- **Shimmer stops:** naturally when the `.loading` state transitions to `.result` or `.error` — the `LoadingPopupText` view is replaced entirely, so no explicit "stop animation" needed

#### Edge Cases

| Scenario | Expected Behavior | Implementation Note |
|----------|------------------|---------------------|
| Translation completes in <100ms (very short text) | Shimmer may not complete a full cycle; result replaces it immediately | Fine — no user-visible problem; `.id(requestID)` reset resets animation state |
| Window resizes during shimmer (content height changes as font renders) | Shimmer must not glitch or restart during height animation | Apply shimmer as a `mask` overlay on `PopupText` — it's size-independent |
| Dark mode | Shimmer gradient must remain visible against dark `.regularMaterial` | Use `Color.white.opacity(0.3)` in the gradient — white shimmer works in both modes |
| Rapid re-trigger (user copies again before first result) | `PopupController` tears down the hosting view tree; new `LoadingPopupText` gets fresh shimmer | Handled by existing architecture |
| Long pivot translation (shimmer runs ~2× duration) | Shimmer must continue through both pivot legs | Shimmer is tied to `LoadingPopupText` lifetime, not to a specific `.translationTask` invocation |
| Reduced Motion accessibility setting | Should respect `@Environment(\.accessibilityReduceMotion)` — no sweep animation; keep the muted text only | Check `accessibilityReduceMotion`; skip shimmer animation if true |

#### Implementation Pattern

```swift
// Conceptual — shimmer modifier applied to PopupText inside LoadingPopupText
PopupText(text: requestContext.sourceText, isMuted: true)
    .shimmer(isActive: true)  // custom ViewModifier
```

The shimmer `ViewModifier` applies a `LinearGradient` mask with an `@State private var offset: CGFloat` animated from `-1.0` to `2.0` (normalized coordinates). Uses `withAnimation(.linear(duration: 1.8).repeatForever(autoreverses: false))` on appear.

---

### Feature 3: Chunked Translation

#### Expected User-Facing Behavior

```
User copies long text (e.g., 450-char paragraph)
↓
Popup opens with source text visible and shimmer running (same loading state as always)
↓
Behind the scenes: text split into 3 chunks at sentence boundaries
↓
All 3 chunks translated (batch or sequential)
↓
Results joined with original separator (\n or space)
↓
Popup shows full translated paragraph (scrollable if > 200pt height)
```

Chunking is **transparent** to the user. They see one result, not three. The only visible difference is (potentially) slightly longer loading time for very long texts, compensated by the shimmer.

#### Splitting Strategy (Priority Order)

1. **Paragraph breaks** (`\n\n`): strongest boundary — always split here
2. **Sentence-ending punctuation + space** (`.` `!` `?` `。` `！` `？` followed by whitespace or end): natural sentence boundary
3. **Line breaks** (`\n`): weaker boundary — use if chunks are still >200 chars after paragraph splits
4. **Whitespace** (as last resort): split at word boundary nearest to 200-char mark
5. **Hard cut** (absolute last resort for single-token dense text like URLs or code): split at char 200

#### Chunk Size Policy

- **Target chunk size:** ≤200 chars (matches popup display height and framework sweet spot)
- **Minimum chunk size:** ~10 chars — chunks shorter than this should be **merged** with the adjacent chunk to avoid fragmenting punctuation or single words
- **Maximum chunk size:** 250 chars with some tolerance (don't split "Paris." from the surrounding sentence just to hit exactly 200)
- **Empty chunks:** filtered out before translation (double spaces, blank lines between paragraphs)

#### Join Strategy

- Chunks joined with the **same separator they were split on**: paragraph breaks join with `\n\n`, sentence breaks join with ` `, line breaks join with `\n`
- **Order preservation is mandatory** — use batch API (`session.translations(from:)`) or a sequential indexed loop, never an unordered `TaskGroup`
- Do not add extra whitespace or punctuation between joined chunks

#### Edge Cases

| Scenario | Expected Behavior | Implementation Note |
|----------|------------------|---------------------|
| Text ≤200 chars | No chunking — single `session.translate()` call | Guard at start of translation action |
| Text with no sentence boundaries (wall of text) | Split at whitespace nearest 200 chars | Fallback splitting strategy |
| CJK text without spaces | CJK sentence-end markers (。！？) are the primary split points | CJK doesn't have word spaces; can split immediately after 。！？ |
| Mixed CJK + Latin text | Both punctuation sets apply — split at whichever comes first after ~150 chars | `。` and `.` both valid sentence ends |
| Single "word" >200 chars (URL, code) | Hard split at char 200 as last resort | Result quality may be poor but at least something is returned |
| Chunk translation fails mid-way | Fail the whole translation (surface error to user) | Use `throws`; first error propagates out of the batch |
| Chunk count creates >10 chunks (very long text) | No upper bound on chunks — translate all; popup scrolls | No artificial limit; Apple Translation handles arrays |
| Pivot + chunking needed | Pivot applies **per-chunk**: each chunk goes through source→EN→target when pair is unsupported | See interaction notes below |
| Leading/trailing whitespace on a chunk | Strip each chunk before translation; restore separator at join | `trimmingCharacters(in: .whitespacesAndNewlines)` per chunk |

#### Pivot × Chunking Interaction

When both pivot and chunking are active (text >200 chars AND pair is unsupported):

**Recommended approach:** detect pair support once, then apply the strategy to all chunks.

```
Option A — Error-triggered per-chunk pivot:
  Try direct translation of chunk[0]
  → unsupportedLanguagePairing error → switch ALL remaining chunks to pivot mode
  → translate chunk[0] via pivot; all subsequent chunks via pivot
  Pros: reuses existing error-catch mechanism
  Cons: chunk[0] is wasted (gets an error then re-translated), adds latency for first chunk

Option B — Proactive pair check before chunking:
  Call LanguageAvailability().status(from: source, to: target) once before chunking
  → if unsupported → use pivot strategy for all chunks from the start
  Cons: Proactive check was removed in v0.4.0 to avoid double ML inference;
        re-adding it for long text only is an acceptable compromise

Option C — Blind pivot for all chunks:
  Always chunk AND always pivot (two-step translation for every chunk)
  Pros: simple, no conditional logic
  Cons: doubles latency for ALL translated text, even supported pairs
  → Rejected
```

**Recommendation:** Option A — detect failure on first chunk, pivot remaining chunks. The first-chunk re-translation overhead is one extra inference (~150ms), which is acceptable given the alternative complexity of re-adding a proactive check.

---

## Feature Dependencies

```
[Shimmer Animation]
    └──requires──> [LoadingPopupText] (existing)
    └──requires──> [PopupText with isMuted=true] (existing)
    └──enhances──> [Chunked Translation] (shimmer runs during longer chunk wait)
    └──enhances──> [Pivot Translation] (shimmer runs during 2-leg wait)

[Pivot Translation]
    └──requires──> [LoadingPopupText with 2-config state machine] (new)
    └──requires──> [TranslationErrorMapper.unsupportedLanguagePair detection] (existing)
    └──interacts──> [Chunked Translation] (pivot strategy must propagate to all chunks)

[Chunked Translation]
    └──requires──> [Text splitting utility] (new)
    └──requires──> [Translation.framework batch API: session.translations(from:)] (verify availability)
    └──interacts──> [Pivot Translation] (chunk error triggers pivot mode for remaining chunks)
    └──enhances──> [Shimmer Animation] (longer loading makes shimmer more visible and valuable)
```

### Dependency Notes

- **Shimmer is independent**: it's a pure visual change to `LoadingPopupText`; it can be built and shipped without pivot or chunking being complete. Build shimmer first — it makes testing of the other two features more pleasant.
- **Pivot requires view state machine extension**: `LoadingPopupText` must grow from one `@State var translationConfiguration` to two. This is a non-trivial change. Requires care around the race guard (both legs must share the same `requestID` and be gated by `activeRequestID`).
- **Chunking is largely contained in the translation action closure**: the `translationAction` static method can be extended to split, batch-translate, and join without changing `PopupView`, `TranslationCoordinator`, or `PopupController`.
- **Pivot × Chunking interaction must be designed explicitly**: if chunking is implemented first, the pivot feature needs to know whether it's operating on chunked mode. Design the translation action to support both modes composably before implementing either fully.

---

## Phase Ordering Recommendation

**Phase 1 — Shimmer animation** (independent, low risk, improves dev feedback loop for subsequent phases)

**Phase 2 — Chunked translation** (self-contained in translation action; tests the batch API; no view state machine changes)

**Phase 3 — Pivot translation** (highest complexity due to two-session view architecture; benefits from chunked being complete so pivot×chunking interaction is implemented together)

---

## Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority | Build Order |
|---------|------------|---------------------|----------|-------------|
| Pivot Translation | HIGH (unblocks JP→DE, ZH→FR, etc. — previously errors) | MEDIUM (two-session state machine) | P1 | 3rd |
| Shimmer Animation | MEDIUM (polish; existing loading UX is acceptable) | LOW (ViewModifier + animation) | P1 | 1st |
| Chunked Translation | MEDIUM (quality/perf for long text; most users copy short passages) | MEDIUM (splitting + batch API) | P1 | 2nd |

All three are P1 for v0.5.0 — they define the milestone. Build order is based on complexity and dependency chain, not priority.

---

## Sources

- Codebase analysis: `PopupView.swift`, `TranslationCoordinator.swift`, `PopupController.swift`, `TranslationErrorMapper.swift` — verified 2026-04-06
- Apple Translation framework architecture: `.translationTask` modifier, `TranslationSession.Configuration`, session lifecycle — derived from existing codebase patterns
- Apple Translation framework supported languages: `LanguageAvailability().supportedLanguages` (runtime), referenced via `SupportedLanguageOption.swift`
- macOS HIG — Reduced Motion accessibility guideline for animation
- SwiftUI shimmer pattern: standard gradient-mask animation approach (widely adopted in iOS/macOS skeleton loading UIs)

---
*Feature research for: Transy v0.5.0 — pivot translation, shimmer animation, chunked translation*
*Researched: 2026-04-06*

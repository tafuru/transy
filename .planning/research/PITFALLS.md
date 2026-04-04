# Pitfalls Research

**Domain:** Adding pivot translation, shimmer animation, and chunked translation to Transy v0.5.0 (macOS 15+, SwiftUI/AppKit, Apple Translation framework, Swift 6 strict concurrency)
**Researched:** 2026-04-04
**Confidence:** HIGH

---

## Critical Pitfalls

### Pitfall 1: Pivot — `unsupportedLanguagePairing` swallowed by `TranslationErrorMapper` before pivot can retry

**What goes wrong:**
The current `translationAction` catch block calls `TranslationErrorMapper.message(for: error)` → `onError(...)` for all non-cancellation errors. `TranslationErrorMapper` already maps `TranslationError.unsupportedLanguagePairing` to the string `"This language pair isn't supported."` and the error path terminates. Pivot never fires because the signal is consumed and converted to a display string before any retry logic can see it.

**Why it happens:**
The catch block was designed to present errors to users. Pivot requires intercepting a specific error and retrying rather than surfacing it. The two concerns (display vs. retry) live in the same catch site today.

**How to avoid:**
Split the catch block in `translationAction`. Catch `TranslationError.unsupportedLanguagePairing` (and `.unsupportedSourceLanguage` / `.unsupportedTargetLanguage`) first, before the generic handler, and invoke the pivot path from there. Only fall through to `onError` if pivot itself fails or is not applicable.

```swift
} catch TranslationError.unsupportedLanguagePairing,
        TranslationError.unsupportedSourceLanguage,
        TranslationError.unsupportedTargetLanguage {
    // trigger pivot — do NOT call onError here
} catch is CancellationError {
    return
} catch {
    await onError(...)
}
```

**Warning signs:**
User copies JP text when target is DE (or any other unsupported direct pair) and sees `"This language pair isn't supported."` instead of a translated result.

**Phase to address:** Pivot Translation (Phase 1 of v0.5.0)

---

### Pitfall 2: Pivot — Two translation legs cannot share one `.translationTask()` session

**What goes wrong:**
The `TranslationSession` provided to the `.translationTask()` action callback is scoped to that callback's execution. It cannot be stored, passed out of the closure, or used after the closure returns. A developer implementing pivot naively may try to translate source→EN and then EN→target using the same session by calling `session.translate()` twice with different content — the second call uses a session configured for the wrong language pair (or auto-detection that may misfire on short English intermediates).

**Why it happens:**
`TranslationSession.Configuration` encodes the source/target language pair. One session = one pair. Reusing the same session for a different pair silently uses the wrong model.

**How to avoid:**
Introduce a second `@State private var pivotConfiguration: TranslationSession.Configuration?` in `LoadingPopupText` and a second `.translationTask(pivotConfiguration, action:)` modifier. The second modifier activates only when pivot is needed (i.e., pivot configuration is non-nil). The second leg's configuration must use `source: Locale.Language(identifier: "en")` — explicitly, not `nil`. With `source: nil` (auto-detect), short or ambiguous intermediate English text may be misidentified, causing the second leg to fail silently.

**Warning signs:**
JP→EN leg succeeds (intermediate English text exists) but EN→DE leg fails with a language detection error, or the DE result is actually EN text passed through unchanged.

**Phase to address:** Pivot Translation (Phase 1 of v0.5.0)

---

### Pitfall 3: Shimmer — animated size change triggers 60fps `repositionPanel()` loop

**What goes wrong:**
`PopupController.show()` attaches a `NotificationCenter` observer for `NSWindow.didResizeNotification` that calls `repositionPanel()` → `panel.setFrameOrigin()`. Any shimmer implementation that alters the view's intrinsic content size on each animation frame (e.g., an animated overlay that slightly changes padding, or a skeleton layout that differs from the source-text `PopupText` dimensions) fires `didResizeNotification` at 60fps. `repositionPanel()` calls `panel.setFrameOrigin()` on every frame, causing the panel to visibly stutter or drift at animation frequency.

**Why it happens:**
The resize observer was designed for discrete content swaps (source text → translation result). Continuous animation was not a design concern when that observer was written.

**How to avoid:**
Shimmer must be a pure cosmetic overlay that never changes the view's frame size. Implement shimmer as an `.overlay` of a clipped `LinearGradient` with an animated `@State var phase: CGFloat` applied via `.mask` or `.blendMode`. The underlying `PopupText(text: sourceText, isMuted: true)` must remain the layout-governing view — same size, same padding. Verify in the Xcode view debugger that the `NSPanel` frame does not change during shimmer animation.

**Warning signs:**
Panel moves slightly left/right (or up/down) during translation loading. Opening `NSWindow.didResizeNotification` observer count in Instruments shows 60 calls/sec while the popup is in loading state.

**Phase to address:** Shimmer Animation (Phase 2 of v0.5.0)

---

### Pitfall 4: Chunked — using sequential `session.translate()` calls instead of the batch API

**What goes wrong:**
Implementing chunked translation as a `for chunk in chunks { let r = try await session.translate(chunk) }` loop multiplies latency: N chunks × single-call latency = N× slowdown compared to the current single `translate()` call. For a 600-char text split into 3 chunks, the translation is now 3× slower, not faster.

**Why it happens:**
`session.translate(_ string: String)` is the familiar API from existing code. The batch API (`session.translations(from: [TranslationSession.Request])`) requires learning a different call signature and response stream, so developers default to what they know.

**How to avoid:**
Use `TranslationSession.translations(from: [TranslationSession.Request])` which returns `async throws -> [TranslationSession.Response]`. The response array is in the same order as the input request array — no `clientIdentifier` reordering is needed. Simply map the responses to their `targetText` and join in array order.

Note: `translate(batch:)` is the `AsyncThrowingStream` variant whose emission order is NOT guaranteed. Do not confuse these two APIs.

**Warning signs:**
Chunked translation of a 600-char text is measurably slower than the v0.4.0 single-call translation of the same text.

**Phase to address:** Chunked Translation (Phase 3 of v0.5.0)

---

### Pitfall 5: Chunked — `NLTokenizer` used in `nonisolated` context violates Swift 6 concurrency

**What goes wrong:**
The current `translationAction` is declared `nonisolated private static func`. `NLTokenizer` (NaturalLanguage framework) is an Objective-C class that does not conform to `Sendable`. Instantiating or calling it within the `nonisolated` async context of `translationAction` will produce a Swift 6 strict-concurrency error: the tokenizer must be used in a consistent isolation domain.

**Why it happens:**
Text chunking feels like a natural extension of `translationAction` since that's where text processing already happens. But `NLTokenizer` carries isolation requirements that `nonisolated` can't satisfy.

**How to avoid:**
Perform text chunking outside of `translationAction`, synchronously on the `@MainActor`, before the session callback fires. The chunk array (an array of `String`, which is `Sendable`) can then be captured in the `translationAction` closure safely. Alternatively, wrap `NLTokenizer` usage in `await MainActor.run { }` inside the nonisolated context — but extracting it beforehand is cleaner and avoids an unnecessary hop back to main.

```swift
// In LoadingPopupText (already @MainActor via SwiftUI view body):
let chunks = TextChunker.chunks(from: requestContext.sourceText) // runs on MainActor
// Pass chunks array into the translationAction closure capture
```

**Warning signs:**
Swift 6 compiler errors like `"Sending 'tokenizer' risks causing data races"` or `"Capture of non-Sendable type 'NLTokenizer'"` when adding chunking logic.

**Phase to address:** Chunked Translation (Phase 3 of v0.5.0)

---

### Pitfall 6: Pivot mid-flight cancellation surfaces intermediate English text

**What goes wrong:**
During pivot, leg 1 (source→EN) completes and returns intermediate English text. Leg 2 (EN→target) begins. If the user dismisses the panel mid-pivot (Escape or outside click), `panel.contentView = nil` destroys the hosted SwiftUI tree, cancelling the `.translationTask()`. The `CancellationError` thrown in leg 2's callback is caught and `return`s cleanly. However, if pivot is implemented by calling `onResult` at the end of leg 1 (before leg 2) with the English text as a "partial result", the user sees raw English output instead of a clean dismiss.

**Why it happens:**
During development, calling `onResult` after leg 1 for debugging purposes. If that call is not removed, it becomes a real user-facing bug.

**How to avoid:**
Never call `onResult` between pivot legs. The `requestID` guard in `finishIfStillActive` would catch some cases, but not all (if the panel hasn't been dismissed yet when leg 1 completes). The pivot flow must call `onResult` only once: after leg 2 produces the final translated text.

**Warning signs:**
When debugging pivot, the popup briefly shows English text before showing the final translated text (flash of intermediate content).

**Phase to address:** Pivot Translation (Phase 1 of v0.5.0)

---

## Moderate Pitfalls

### Pitfall 7: Pivot — race between `unsupportedLanguagePairing` detection and a new clipboard event

**What goes wrong:**
Leg 1 of pivot throws `unsupportedLanguagePairing`, the catch block detects it, and pivot leg 2 setup begins (setting `pivotConfiguration`). In this window, a new clipboard event fires: `translationCoordinator.begin()` issues a new `requestID`. When pivot leg 2 eventually completes, its `finishIfStillActive` guard correctly rejects the stale result (the stored `requestContext.requestID` is the old one). **However**, if the pivot leg 2 `.translationTask()` view is still alive (the new `requestID` uses `.id(newRequestID)` which creates a new `LoadingPopupText` instance), the old view's pivot session may still be running concurrently against the new request's session.

**How to avoid:**
`.id(requestID)` on `LoadingPopupText` in `PopupView.body` already causes SwiftUI to destroy and recreate the view on each new request. This tears down both `.translationTask()` modifiers for the old request (including any mid-flight pivot session). Ensure pivot state (`@State var pivotConfiguration`) lives inside `LoadingPopupText` (not in a parent), so it's destroyed with the view identity change.

**Phase to address:** Pivot Translation (Phase 1 of v0.5.0)

---

### Pitfall 8: Chunked — empty or whitespace-only chunks passed to `translate()`

**What goes wrong:**
`NLTokenizer` with `.sentence` unit can emit ranges that produce empty strings or whitespace-only strings (e.g., between consecutive newlines, trailing whitespace after a sentence end). Passing `""` to `session.translate()` may return an empty response, throw an error, or return the empty string unchanged — but all three outcomes corrupt the joined result if not filtered before submission.

**How to avoid:**
Filter chunks with `chunk.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty` before building `[TranslationSession.Request]`. Track the original positions of non-empty chunks to correctly reconstruct the final joined string (preserve spacing between chunks from the original text, do not re-derive from translated output).

**Phase to address:** Chunked Translation (Phase 3 of v0.5.0)

---

### Pitfall 9: Shimmer — animation does not start because `withAnimation` fires before panel is visible

**What goes wrong:**
If the shimmer's `withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) { phase = 1.0 }` is triggered in a `.task {}` modifier, it may fire before the panel has completed its 0.15s `alphaValue` fade-in. On macOS, SwiftUI animations inside `NSHostingView` that start before the hosting view is in a visible window may be skipped or have their initial frame computed wrong, resulting in a shimmer that appears static or jumps to the end state.

**How to avoid:**
Start the shimmer animation in `.onAppear` (not `.task`, not the view initializer). `.onAppear` fires after SwiftUI has committed the view to the display tree, which on macOS corresponds to the hosting view being installed in the panel — after `panel.orderFrontRegardless()`.

**Phase to address:** Shimmer Animation (Phase 2 of v0.5.0)

---

### Pitfall 10: Shimmer — `accessibilityReduceMotion` ignored

**What goes wrong:**
macOS System Settings → Accessibility → Display → Reduce Motion signals that the user does not want animated effects. SwiftUI exposes `@Environment(\.accessibilityReduceMotion)`. If shimmer ignores this, users who opted out of motion see a continuously pulsing effect — the opposite of their stated preference.

**How to avoid:**
Read `@Environment(\.accessibilityReduceMotion)` in the shimmer view. When `true`, substitute a static low-opacity treatment (e.g., constant `opacity(0.4)`) instead of the moving gradient. The substitution can be a simple conditional — no separate view needed.

**Phase to address:** Shimmer Animation (Phase 2 of v0.5.0)

---

### Pitfall 11: Chunked — missing short-text bypass makes common case slower

**What goes wrong:**
`NLTokenizer` initialization, language hint configuration, and sentence enumeration add overhead. For the common case of selected text under 200 characters (the majority of copy-translate interactions), running the chunking pipeline produces a single chunk and exits — paying tokenizer overhead for no benefit.

**How to avoid:**
Add a fast-path guard at the entry to the chunking function:
```swift
guard text.count > 200 else { return [text] }
```
This keeps the common path identical to v0.4.0 performance.

**Phase to address:** Chunked Translation (Phase 3 of v0.5.0)

---

### Pitfall 12: Pivot + Chunked combination requires explicit design

**What goes wrong:**
If both features are implemented independently without considering their combination, a long unsupported-pair text (e.g., 600-char JP→DE) requires N chunks × 2 pivot legs = 2N session calls. Without a clear design for this interaction, the implementation either silently skips pivot for chunked text, errors on the first chunk, or attempts to establish 2N `.translationTask()` sessions (which is not the right architecture).

**Why it happens:**
Each feature is designed in isolation. Their interaction is not considered until integration.

**How to avoid:**
Address pivot (Phase 1) and chunked (Phase 3) in sequence, not in parallel. At Phase 3 design time, explicitly test the combined path: a chunked long text with an unsupported language pair. The correct behavior is for each chunk to be translated via the pivot path (chunk→EN→target). This likely means pivot detection happens at the individual chunk level, or the first chunk detects unsupported pair and the remaining chunks use pivot without a second detection attempt.

**Phase to address:** Chunked Translation (Phase 3 of v0.5.0), with pivot awareness

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Detect pivot need per-chunk (first chunk throws, all chunks retry via pivot) | Simple: no preflight, same error-driven detection pattern | 1 wasted first-leg call per chunk when pair is known-unsupported | Acceptable in v0.5.0 — pair info is not cached and preflight was explicitly removed |
| Static shimmer (no animation) when `accessibilityReduceMotion` is true | Zero extra complexity | User who enabled reduce motion sees no feedback improvement | Acceptable — static opacity is still better than v0.4.0 |
| Sequential chunk joining (no progressive display) | Simple coordinator — single `finish()` call | Long texts feel slower than v0.4.0 single call during chunking | Acceptable in v0.5.0 — progressive display requires coordinator state machine changes |
| Hard 200-char fallback when no sentence boundary found | Simple, predictable | May split mid-word for CJK text without sentence punctuation | Acceptable — better to split than to fail; CJK sentence detection via NLTokenizer is reliable for common text |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| `TranslationSession` + pivot | Calling `session.translate()` twice in one callback for different pairs | Two separate `.translationTask()` modifiers, each with its own `@State` configuration |
| `TranslationSession.translations(from:)` | Assuming response order = input order | Always key responses by `clientIdentifier` before joining |
| `NLTokenizer` + `nonisolated` action | Instantiating tokenizer inside the `translationAction` closure | Chunk text on `@MainActor` before session callback; pass `[String]` (Sendable) into closure |
| `NSWindow.didResizeNotification` + shimmer | Shimmer altering view frame size on each frame | Shimmer must be a zero-layout-impact `.overlay`; verify panel frame is static during animation |
| `TranslationErrorMapper` + pivot | Leaving error mapper in the `catch` path for unsupported pair errors | Intercept `unsupportedLanguagePairing` before the generic error mapper |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Shimmer triggers resize notifications | Panel visually jitters during loading; Instruments shows 60 `didResizeNotification` events/sec | Shimmer as size-stable overlay; check panel frame in view debugger | Immediately, on any shimmer implementation that changes layout |
| Sequential `translate()` for chunks | 3-chunk text takes 3× longer than v0.4.0 for same character count | Use `translations(from:)` batch API | Every chunked translation |
| No short-text bypass for chunker | All translations (including 20-char words) pay tokenizer overhead | `guard text.count > 200 else { return [text] }` | Every translation in normal usage |
| Pivot per-chunk without caching pair support | A 600-char unsupported-pair text makes 3 wasted first-leg calls before falling back to pivot | Cache detected-unsupported flag within a request's chunk loop | Every multi-chunk unsupported-pair translation |

---

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Shimmer size differs from source text `PopupText` | Popup visually resizes when loading state starts, then resizes again when result arrives | Shimmer overlays existing `PopupText(text: sourceText, isMuted: true)` — same layout, same size |
| Pivot shows intermediate English text briefly | Confusing flash of English before target language appears | Never call `onResult` between pivot legs; only call after leg 2 completes |
| Shimmer animates during `accessibilityReduceMotion` | Violates user accessibility preference | Static opacity fallback when `accessibilityReduceMotion` is true |
| Chunked translation with no progressive feedback | Long text feels frozen for longer than v0.4.0 | Shimmer communicates "in progress"; consider showing chunk count in loading state |

---

## "Looks Done But Isn't" Checklist

- [ ] **Pivot:** Verify with JP→DE (or any non-EN pair) — not just EN↔JP. Error message must not appear; translated text in target language must appear.
- [ ] **Pivot:** Verify dismiss during leg 1 → no flash of English text, no error shown. Clean dismiss.
- [ ] **Pivot:** Verify dismiss during leg 2 → no English intermediate shown, clean dismiss.
- [ ] **Shimmer:** Open Instruments → Core Animation and confirm 0 layout passes during shimmer animation loop.
- [ ] **Shimmer:** Enable Reduce Motion in System Settings → Accessibility → Display. Confirm shimmer is replaced with static treatment.
- [ ] **Shimmer:** Confirm panel does not move during shimmer (check `panel.frame` before and after 1 full animation cycle).
- [ ] **Chunked:** Benchmark 600-char text translation time — must be ≤ 1.5× current single-call time, not 3×.
- [ ] **Chunked:** Verify text with only whitespace/newlines between sentences does not produce empty-chunk errors.
- [ ] **Chunked + Pivot:** Test a 600-char JP text with target=DE — confirm all chunks arrive translated into German, not English.
- [ ] **Swift 6:** Zero concurrency warnings/errors with strict concurrency enabled for all three features.

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| `unsupportedLanguagePairing` swallowed by error mapper | LOW | Add a specific `catch` clause above the generic handler; no architecture change needed |
| Two-session pivot using wrong session | MEDIUM | Introduce second `@State` configuration + second `.translationTask()` modifier; refactor `translationAction` to accept chunk array |
| Shimmer causing resize loop | LOW | Remove any size-changing properties from shimmer implementation; use `.overlay` + `.clipped()` |
| Sequential translate() loop | MEDIUM | Replace with `translations(from:)` batch call; add `clientIdentifier` → index mapping |
| `NLTokenizer` Swift 6 error | LOW | Move tokenization to synchronous pre-step on `@MainActor`; pass `[String]` chunks into closure |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| `unsupportedLanguagePairing` swallowed before pivot | Phase: Pivot Translation | JP→DE test produces translated German output, not an error string |
| Wrong session reused for pivot second leg | Phase: Pivot Translation | EN→DE leg uses explicit `source: en` configuration; German output confirmed |
| Pivot shows intermediate English | Phase: Pivot Translation | Dismiss during leg 1 and leg 2 produce clean dismisses; no English flash |
| Pivot + new request race | Phase: Pivot Translation | Rapid double-copy during pivot shows only the second request's result |
| Shimmer triggers resize/reposition loop | Phase: Shimmer Animation | Panel position is static during animation; 0 resize notifications per animation frame |
| Shimmer ignores `accessibilityReduceMotion` | Phase: Shimmer Animation | Reduce Motion enabled → static opacity instead of moving gradient |
| Shimmer animation starts before panel visible | Phase: Shimmer Animation | Animation is smooth from first visible frame; no jump/skip on panel open |
| Batch API not used for chunks | Phase: Chunked Translation | 600-char text benchmarks ≤1.5× single-call time |
| `NLTokenizer` in `nonisolated` context | Phase: Chunked Translation | Zero Swift 6 strict-concurrency warnings after chunking implementation |
| Empty chunks from tokenizer | Phase: Chunked Translation | Text with consecutive newlines translates without errors or empty segments |
| No short-text bypass | Phase: Chunked Translation | Single-word translation performance matches v0.4.0 |
| Pivot + Chunked interaction | Phase: Chunked Translation | 600-char JP→DE text produces fully translated German output |

---

## Sources

- Apple Developer Documentation: `Translation.TranslationSession`, `.translationTask()` modifier, `TranslationSession.Configuration`, `TranslationSession.Request`
- Apple Developer Documentation: `NaturalLanguage.NLTokenizer` — isolation and Sendable constraints
- Swift 6 Strict Concurrency — nonisolated contexts and Sendable capture rules
- Codebase analysis: `PopupView.swift`, `PopupController.swift`, `TranslationErrorMapper.swift`, `TranslationCoordinator.swift`
- `NSWindow.didResizeNotification` behavior with `NSHostingView` and continuous SwiftUI animations

---
*Pitfalls research for: Transy v0.5.0 — pivot translation, shimmer animation, chunked translation*
*Researched: 2026-04-04*

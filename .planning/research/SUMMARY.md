# Project Research Summary

**Project:** Transy v0.5.0 — Translation Quality Milestone
**Domain:** macOS menu bar utility — selected-text translation (v0.5.0 additions: pivot, shimmer, chunked)
**Researched:** 2026-04-06
**Confidence:** HIGH (all APIs verified against macOS SDK swiftinterface files; architecture derived from direct codebase read)

---

## Executive Summary

The v0.5.0 milestone adds three features to the shipped v0.4.0 foundation: **English pivot translation** (silently retries unsupported language pairs via English), **shimmer loading animation** (replaces the static muted placeholder with an animated gradient sweep), and **chunked translation** (splits long texts at sentence boundaries before batch-translating). All three are required to ship the milestone. Critically, **no new package dependencies are needed** — the complete implementation uses Apple Translation.framework, NaturalLanguage.framework (bundled since macOS 10.14), and pure SwiftUI, all already within the project's macOS 15 deployment floor.

The central architectural insight is that Apple Translation sessions are **view-scoped, not instantiable directly**. This shapes every design decision. Pivot requires two separate `.translationTask()` modifiers in `LoadingPopupText` (one per language pair) coordinated through a new `PivotTranslationState` `@Observable` class — not a single session called twice. Chunking must use the batch API `TranslationSession.translations(from: [Request])`, which returns results in **guaranteed input order** (confirmed in SDK swiftinterface), not sequential `translate()` loops which would multiply latency N×. The `NLTokenizer(unit: .sentence)` used for sentence-boundary splitting must run synchronously on `@MainActor` before entering the `nonisolated` translation action, because `NLTokenizer` is not `Sendable` under Swift 6 strict concurrency.

The highest risk is **shimmer triggering the NSPanel resize loop**: `PopupController` has a `NotificationCenter` observer for `NSWindow.didResizeNotification` that calls `repositionPanel()` on every event. Any shimmer implementation that changes the view's layout frame will fire that notification at 60fps, visibly jittering the panel. Shimmer must be implemented as a zero-layout-impact `.overlay` that never alters the underlying `PopupText` dimensions. Build order recommendation: **Phase 14 Shimmer → Phase 15 Chunked → Phase 16 Pivot**, with shimmer's isolation making it a safe first deliverable and pivot's two-session state machine warranting the most careful integration.

---

## Key Findings

### Recommended Stack

No new packages. All additions are system-framework imports already available at the macOS 15 deployment floor.

**Core technologies (v0.5.0 additions only):**
- **`Translation.framework`** (already imported) — `TranslationSession.translations(from:)` for batch chunked translation; `Configuration.invalidate()` for pivot leg re-triggering; `TranslationError.unsupportedLanguagePairing/unsupportedSourceLanguage/unsupportedTargetLanguage` for error-driven pivot detection.
- **`NaturalLanguage.framework`** (`import NaturalLanguage` in new `TextChunker.swift` only) — `NLTokenizer(unit: .sentence)` for language-aware sentence-boundary splitting. Bundled since macOS 10.14; no entitlement; no SPM dependency.
- **SwiftUI** (already imported) — pure `ViewModifier` shimmer via `LinearGradient` + `withAnimation(.linear.repeatForever(autoreverses: false))`; `TimelineView(.animation)` available as a fallback shimmer driver if needed.

**Critical API details verified in SDK swiftinterface:**
- `translations(from: [Request]) -> [Response]` returns results **in the same order as input** — no `clientIdentifier` sort needed for reassembly. (Note: PITFALLS.md Pitfall 4 contradicts this; STACK.md's SDK-verified finding takes precedence.)
- `TranslationSession.Strategy` (highFidelity/lowLatency) requires macOS 26.4 — **do not use** (above the project floor).
- `Locale.Language(languageCode: .english)` is available from macOS 13 (`@_alwaysEmitIntoClient` static constant in Foundation).
- `LanguageAvailability.status()` must **not** be used as a preflight — explicitly removed in v0.4.0 to eliminate double ML inference per request.

### Expected Features

**Must have — all define v0.5.0 (no deferral):**
- **English pivot translation** — unsupported pairs (JP→DE, ZH→FR, etc.) silently route via English; user receives target-language result with no error, no intermediate English flash, no "via English" label.
- **Shimmer/skeleton animation** — `LinearGradient` overlay sweeps across the muted source text at ~1.5–2s per cycle; respects `accessibilityReduceMotion`; stops naturally when `LoadingPopupText` is replaced.
- **Chunked translation** — texts >200 chars split at sentence boundaries via `NLTokenizer`; all chunks submitted as a single batch via `translations(from:)`; results joined preserving original separators.

**Differentiators (built-in to the above):**
- Transparent pivot — no user-visible indication that English is being used as an intermediary.
- Shimmer preserves source text readability — the shimmer overlays the muted source text, not blank placeholder bars. This is a deliberate design principle carried from v0.4.0.
- Sentence-boundary chunking — `NLTokenizer` handles `。!?.！？` plus language-aware boundaries; naïve character splits are explicitly rejected.

**Anti-features (explicitly do not build):**
- "Translating via English…" progress label — reveals implementation detail; surfaces failure paths without benefit.
- Parallel chunk translation with `TaskGroup` — `translations(from:)` handles parallelism internally; `TaskGroup` adds complexity for no gain.
- Per-chunk error recovery — over-engineering; the failure modes are pair-level, not chunk-level.
- Configurable chunk size in Settings — the 200-char threshold is an implementation constant, not a user-facing knob.
- Animated pivot phase progress — two on-device inferences take ~300ms; phase indicators are visible only for a flash.
- `TranslationSession.Strategy` (highFidelity/lowLatency) — requires macOS 26.4.

### Architecture Approach

All three features are **additive changes to `LoadingPopupText`** in `PopupView.swift`; `TranslationCoordinator`, `PopupController`, `AppDelegate`, and `TextNormalization` are **unchanged**. The existing `PopupState` state machine, `requestID` race guard, and `configuration.invalidate()` mechanism are all reused without modification.

**New files:**
1. `Transy/Translation/PivotTranslationState.swift` — `@MainActor @Observable final class PivotTranslationState` holding `PivotPhase` enum (`.direct`, `.firstLeg`, `.secondLeg(intermediate: String)`). Encapsulates pivot as a translation-engine detail, not a coordinator concern.
2. `Transy/Popup/ShimmerModifier.swift` — `ShimmerModifier: ViewModifier` + `View.shimmer()` extension. Pure SwiftUI struct; no actor isolation; no state machine.
3. `Transy/Translation/TextChunker.swift` — `enum TextChunker` with `static func chunks(from:maxLength:) -> [String]`. Fast path: `guard text.count > 200 else { return [text] }`. Pure `Foundation` + `NaturalLanguage`; fully unit-testable with no Translation framework dependency.

**Modified files:**
- `Transy/Popup/PopupView.swift` (all three features touch `LoadingPopupText`): add `@State private var pivotState = PivotTranslationState()`, second `.translationTask(pivotConfiguration, action:)` modifier, `.shimmer()` on `PopupText(sourceText, isMuted: true)`, and chunk loop in the translation action.
- `Transy/Translation/TranslationErrorMapper.swift`: extract `static func isPivotableError(_ error: any Error) -> Bool` from the existing `unsupportedLanguagePairing` match.

**Pivot data flow:**
```
translationAction → catch unsupportedLanguagePairing
  → pivotState.phase = .firstLeg
  → .onChange(pivotState.phase) → invalidate config to (source: nil, target: .english)
  → translationAction fires again → intermediate English result
  → pivotState.phase = .secondLeg(intermediate)
  → .onChange → invalidate config to (source: .english, target: targetLanguage)
  → translationAction fires again → onResult(finalTranslation)
```

**Swift 6 concurrency invariants:**
- `translationAction` remains `nonisolated static`; all `@Sendable` callback closures route `@MainActor` mutations through `await MainActor.run {}`.
- `PivotTranslationState` is `@MainActor`-isolated → `Sendable` as a reference type; safe to capture in `@Sendable` closures.
- `PivotPhase` contains only `String` → satisfies `Sendable`.
- `NLTokenizer` (non-`Sendable`) must run synchronously on `@MainActor` inside `LoadingPopupText.body` **before** the `nonisolated translationAction` closure captures the resulting `[String]` chunk array.

### Critical Pitfalls

1. **`unsupportedLanguagePairing` swallowed by `TranslationErrorMapper` before pivot fires** (Critical) — the existing generic catch block converts this error to a display string and calls `onError`, terminating before any pivot logic runs. Fix: add a specific `catch TranslationError.unsupportedLanguagePairing, ...` clause *above* the generic handler; invoke pivot from there; only fall through to `onError` if pivot itself fails. (PITFALLS.md §1)

2. **Shimmer triggers `repositionPanel()` at 60fps** (Critical) — `PopupController` observes `NSWindow.didResizeNotification` and calls `panel.setFrameOrigin()` on every event. Any shimmer that alters view layout on each frame (padding change, different intrinsic size) fires this 60× per second, visibly jittering the panel position. Fix: shimmer must be a `LinearGradient` `.overlay` with `.clipped()`; the underlying `PopupText` dimensions must be identical to non-shimmer state; verify panel frame is static during animation in the Xcode view debugger. (PITFALLS.md §3)

3. **Two pivot legs cannot share one `.translationTask()` session** (Critical) — `TranslationSession.Configuration` encodes the source/target language pair; one session = one pair; calling `session.translate()` twice in the same callback for different pairs silently uses the wrong model. Fix: introduce a second `@State private var pivotConfiguration: TranslationSession.Configuration?` and a second `.translationTask(pivotConfiguration, action:)` modifier; the second modifier activates only when pivot is needed. Leg 2 config must use `source: Locale.Language(identifier: "en")` explicitly — NOT `source: nil` (auto-detect misidentifies short English intermediates). (PITFALLS.md §2)

4. **`NLTokenizer` in `nonisolated` context → Swift 6 concurrency error** (Critical) — `NLTokenizer` is an Obj-C class not conforming to `Sendable`; instantiating it inside `nonisolated translationAction` will produce `"Sending 'tokenizer' risks causing data races"`. Fix: perform chunking synchronously on `@MainActor` in `LoadingPopupText.body` before the session callback; pass the resulting `[String]` (which is `Sendable`) into the closure. (PITFALLS.md §5)

5. **Sequential `translate()` loop for chunks multiplies latency N×** (Critical) — a `for chunk in chunks { let r = try await session.translate(chunk) }` loop makes N sequential inference calls; a 3-chunk text is 3× slower than v0.4.0. Fix: use `session.translations(from: [TranslationSession.Request])` which submits all chunks in one batch call and returns ordered `[Response]`. (PITFALLS.md §4 / STACK.md §Feature 3)

6. **Pivot shows intermediate English text on dismiss** (Moderate) — if `onResult` is called after leg 1 (even for debugging), users may see raw English output before dismissal tears down the view. Fix: `onResult` must be called exactly once — after leg 2. (PITFALLS.md §6)

7. **Shimmer animation starts before panel is visible** (Moderate) — starting animation in `.task` may fire before the panel's 0.15s `alphaValue` fade-in completes, causing a static or jumped shimmer. Fix: use `.onAppear`, not `.task`. (PITFALLS.md §9)

8. **`accessibilityReduceMotion` ignored by shimmer** (Moderate) — violates user accessibility preference. Fix: read `@Environment(\.accessibilityReduceMotion)` and substitute a static `opacity(0.4)` treatment when true. (PITFALLS.md §10)

---

## Implications for Roadmap

Based on combined research, the v0.5.0 milestone maps cleanly to three sequential implementation phases. The ordering is driven by dependency and integration risk, not by feature priority (all three are P1).

### Phase 14: Shimmer Animation

**Rationale:** Most isolated feature — zero logic dependencies, zero state machine changes, no Translation framework surface. Building shimmer first means the loading UI looks polished during testing of the other two features (pivot and chunked both extend loading duration, making shimmer more valuable and visible). Low risk makes it the safest first deliverable.

**Delivers:** `ShimmerModifier.swift` (new); one-line change to `LoadingPopupText.body`; `accessibilityReduceMotion` support.

**Addresses:** Shimmer animation (table stakes), shimmer-preserves-source-text differentiator.

**Must avoid:**
- Shimmer altering view layout frame (NSPanel resize loop at 60fps — Pitfall 3)
- Starting animation in `.task` instead of `.onAppear` (Pitfall 9)
- Ignoring `accessibilityReduceMotion` (Pitfall 10)

**Research flag:** None — well-documented SwiftUI animation pattern; standard `ViewModifier` approach.

---

### Phase 15: Chunked Translation

**Rationale:** Self-contained in `TextChunker.swift` + `translationAction`; does not change the view state machine; its test suite validates `TextChunker` with zero Translation framework dependency. Must be built before pivot because pivot's combined path (long unsupported-pair text) requires `TextChunker` to exist inside each pivot leg's action. Building chunking first means pivot integration is complete, not deferred.

**Delivers:** `TextChunker.swift` (new); `translationAction` extended with chunk loop using `translations(from:)` batch API; `import NaturalLanguage` in `TextChunker.swift` only.

**Addresses:** Chunked translation (table stakes), sentence-boundary chunking differentiator.

**Must avoid:**
- Sequential `translate()` loop instead of `translations(from:)` batch API (Pitfall 4 / latency N× trap)
- `NLTokenizer` instantiated inside `nonisolated translationAction` (Swift 6 Pitfall 5) — must run on `@MainActor` before session callback
- Missing short-text bypass: `guard text.count > 200 else { return [text] }` (Pitfall 11 / perf trap)
- Passing empty or whitespace-only chunks to `translate()` (Pitfall 8)

**Research flag:** None — `TextChunker` is a pure utility; `NLTokenizer` patterns are well-documented; batch API signature verified in SDK.

---

### Phase 16: English Pivot Translation

**Rationale:** Highest complexity due to two-session view architecture and state machine in `LoadingPopupText`. Benefits from both shimmer (running throughout both legs without modification) and chunked translation (pivot legs reuse `TextChunker` transparently) being complete. Pivot's `PivotTranslationState` `@Observable` class mirrors existing patterns; the risk is contained within `LoadingPopupText` + `TranslationErrorMapper`.

**Delivers:** `PivotTranslationState.swift` (new); `LoadingPopupText` extended with second `@State pivotConfiguration` + second `.translationTask` modifier; `TranslationErrorMapper.isPivotableError(_:)` extracted.

**Addresses:** English pivot translation (table stakes), transparent pivot differentiator, JP→DE / ZH→FR unblocked.

**Must avoid:**
- `unsupportedLanguagePairing` consumed by existing error mapper before pivot fires (Pitfall 1 — split catch block)
- Leg 2 session using `source: nil` (auto-detect misidentifies short English intermediates; must use explicit `source: Locale.Language(identifier: "en")`) (Pitfall 2)
- `onResult` called between pivot legs (intermediate English flash) (Pitfall 6)
- Pivot state (`@State pivotConfiguration`) in a parent view rather than inside `LoadingPopupText` — must be destroyed with the view identity on new `requestID` (Pitfall 7)
- Pivot + chunked combined path not explicitly designed: 600-char JP→DE requires all chunks to pivot; detect unsupported pair on first chunk, then apply pivot strategy to remaining chunks without re-detecting (Pitfall 12)

**Research flag:** Needs careful integration review — two-session coordination is the only unexplored Apple Translation surface in this milestone. The `configuration.invalidate()` mechanism already works (proven by the existing per-request flow); multi-invalidation within a single user trigger is an extension of the same mechanism, so confidence is HIGH but implementation correctness must be verified with JP→DE and ZH→FR test cases.

---

### Phase Ordering Rationale

- **Shimmer first** because it is entirely decoupled; its code paths do not interact with Translation framework state; having it live makes testing of phases 15 and 16 significantly more pleasant (animated feedback during longer loading states).
- **Chunked second** because `TextChunker` is a self-contained pure utility, testable without any framework dependency; and because pivot's combined long-text path requires `TextChunker` to already exist inside the translation action closure before pivot is integrated.
- **Pivot third** because it has the highest integration complexity; it benefits from shimmer already handling the extended loading duration across two legs; and from chunked already being in place for the pivot+chunked combined path. Building pivot last means all its dependencies are stable.

This order also isolates risk: shimmer and chunked can be merged and shipped independently if needed, without blocking pivot.

---

### Research Flags

Phases with standard patterns (no additional phase research needed):
- **Phase 14 (Shimmer):** Well-documented SwiftUI `ViewModifier` pattern; only risk is NSPanel resize behavior (known, mitigated by zero-layout-impact overlay).
- **Phase 15 (Chunked):** `NLTokenizer` and `translations(from:)` batch API both verified against SDK; `TextChunker` is a pure utility with straightforward unit tests.

Phases that benefit from careful pre-implementation review (not full research, but deliberate design review):
- **Phase 16 (Pivot):** The two-`.translationTask` coordination pattern has not been exercised in the codebase before. The `configuration.invalidate()` mechanism is proven for the single-request case; its sequential multi-invalidation behavior within one user trigger is HIGH confidence from the research but should be prototyped and verified before full implementation. Specifically: confirm SwiftUI does not coalesce rapid successive `configuration.invalidate()` calls, and verify that `.id(requestID)` on `LoadingPopupText` tears down both `.translationTask` modifiers cleanly when a new clipboard event arrives mid-pivot.

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All APIs verified against arm64e macOS SDK swiftinterface files; no inferred behavior |
| Features | HIGH | Derived from direct codebase analysis + Apple Translation framework constraints; edge cases documented with specific implementation notes |
| Architecture | HIGH (existing) / MEDIUM (pivot multi-session) | Existing v0.4.0 architecture read directly from codebase; pivot two-`.translationTask` coordination is architecturally sound but not yet exercised |
| Pitfalls | HIGH | All critical pitfalls derived from actual code paths in `PopupView.swift`, `PopupController.swift`, `TranslationErrorMapper.swift`; NSPanel resize behavior is a known macOS pattern |

**Overall confidence: HIGH**

### Gaps to Address

- **`translations(from:)` ordering guarantee vs. `clientIdentifier` sort** — STACK.md (SDK-verified) states output order matches input order; PITFALLS.md §4 contradicts this and recommends keying by `clientIdentifier`. STACK.md's SDK-verified finding takes precedence. Verify empirically during Phase 15 implementation with a multi-chunk text and assert response order.
- **Concurrent `.translationTask()` safety** — it is undocumented whether multiple concurrent `session.translate()` calls on the same `TranslationSession` instance are safe. The chosen sequential chunk loop avoids this concern; document the decision in `TextChunker.swift` with a comment.
- **Pivot multi-invalidation behavior** — `configuration.invalidate()` is proven for the single-request case; behavior with 2–3 rapid sequential invalidations within one user trigger is HIGH confidence from research but should be confirmed early in Phase 16 with a prototype before full state machine build-out.
- **Shimmer on light vs. dark system appearance** — `Color.white.opacity(0.25)` peak works for dark `regularMaterial`; verify on light system appearance during Phase 14 and adjust opacity/gradient stops if needed.

---

## Sources

### Primary (HIGH confidence — SDK-verified)
- `Translation.framework` — `arm64e-apple-macos.swiftinterface` (Translation version 365.8.2) — `TranslationSession`, `TranslationError`, `LanguageAvailability`, `translations(from:)` ordering guarantee
- `NaturalLanguage.framework` — `NLTokenizer.h` — `NLTokenUnit.sentence`, `enumerateTokensInRange:usingBlock:`
- `Foundation.framework` — `arm64e-apple-macos.swiftinterface` — `Locale.Language(languageCode:)`, `Locale.LanguageCode.english`
- `SwiftUI.framework` — `arm64e-apple-macos.swiftinterface` — `TimelineView`, `AnimationTimelineSchedule` availability (macOS 12+)
- Codebase direct read — `PopupView.swift`, `TranslationCoordinator.swift`, `PopupController.swift`, `TranslationErrorMapper.swift`, `SupportedLanguageOption.swift` — verified 2026-04-06

### Secondary (MEDIUM confidence)
- `.planning/PROJECT.md` — confirmed removal of `LanguageAvailability.status()` preflight in v0.4.0
- Apple Developer Documentation: Translation framework, `NSPanel`, `NSWindow.didResizeNotification`
- WWDC24: Meet the Translation API
- macOS HIG — Reduced Motion accessibility guideline

---
*Research completed: 2026-04-06*
*Covers: Transy v0.5.0 — pivot translation, shimmer animation, chunked translation*
*Supersedes: 2026-03-14 baseline research summary (v0.4.0)*
*Ready for roadmap: yes*

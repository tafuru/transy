# Stack Research

**Domain:** macOS menu bar utility — selected-text translation (v0.5.0 additions)
**Researched:** 2026-04-05
**Confidence:** HIGH (all APIs verified against macOS SDK swiftinterface files)

---

## Overview

This document covers the **v0.5.0 stack additions** required for three new features: English pivot translation, shimmer loading animation, and chunked translation for long text. The baseline stack (Swift 6, SwiftUI, AppKit, Translation.framework, XcodeGen) is unchanged.

No new package dependencies are needed. All required APIs ship with macOS 15+.

---

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Swift | 6.0 (Xcode 16) | Primary language | Unchanged from v0.4.0. Strict concurrency with `@MainActor` isolation already proven. |
| Translation.framework | macOS 15+ | Pivot chaining + batch translation | `TranslationSession.translations(from:)` returns ordered batch results; `Configuration.invalidate()` drives pivot leg re-triggering. Both confirmed in SDK swiftinterface. |
| NaturalLanguage.framework | macOS 10.14+ (bundled) | Sentence-boundary chunking | `NLTokenizer(unit: .sentence)` is the correct API for splitting at sentence boundaries. Present in all macOS versions above the project floor. No import overhead. |
| SwiftUI | macOS 12+ for `TimelineView`, macOS 15+ target | Shimmer animation | `LinearGradient` + `@State`-driven `withAnimation(.linear.repeatForever)` overlay — pure SwiftUI, zero dependencies. `TimelineView(.animation)` confirmed available macOS 12+. |

---

## New API Surface by Feature

### Feature 1: English Pivot Translation

All APIs are in the already-imported `Translation` framework.

| API | Availability | Role |
|-----|-------------|------|
| `TranslationError.unsupportedLanguagePairing` | macOS 15+ | Trigger pivot — catch from the first `.translationTask` action instead of pre-checking |
| `TranslationError.unsupportedSourceLanguage` | macOS 15+ | Also triggers pivot (source not identified as a supported language) |
| `TranslationError.unsupportedTargetLanguage` | macOS 15+ | Also triggers pivot (target language has no direct model from source) |
| `TranslationSession.Configuration(source: Locale.Language?, target: Locale.Language?)` | macOS 15+ | Pivot leg 1: `(source: nil, target: Locale.Language(languageCode: .english))`; Pivot leg 2: `(source: Locale.Language(languageCode: .english), target: targetLanguage)` |
| `configuration.invalidate()` | macOS 15+ | Forces `.translationTask` to provide a new session with the updated language pair |
| `Locale.Language(languageCode: .english)` | macOS 13+ | Canonical English language value for pivot. `Locale.LanguageCode.english` is an `@_alwaysEmitIntoClient` static constant confirmed in Foundation swiftinterface |

**Integration pattern with existing code:**

`LoadingPopupText` already uses a `@State var translationConfiguration` that drives `.translationTask`. Pivot extends this with a second state property tracking pivot phase:

```swift
enum PivotPhase: Equatable {
    case direct
    case pivotLeg1(originalSource: String)   // targeting English
    case pivotLeg2(pivotText: String)         // targeting real target language
}
@State private var pivotPhase: PivotPhase = .direct
```

When the action closure catches an unsupported-pair error in `.direct` phase, it sets `pivotPhase = .pivotLeg1(...)` and updates `translationConfiguration` to target English + calls `configuration.invalidate()`. This re-triggers `.translationTask` with a new session. Leg 1 success stores `pivotText` and sets `pivotPhase = .pivotLeg2(...)`, updating config to `(source: .english, target: targetLanguage)`. Leg 2 success calls `onResult`.

**Do NOT use `LanguageAvailability.status()` as a preflight.** The project already removed it (causes double ML inference per request). Catch the error and retry instead.

---

### Feature 2: Shimmer / Skeleton Animation

No new framework needed. Pure SwiftUI `ViewModifier`.

| API | Availability | Role |
|-----|-------------|------|
| `@State var shimmerPhase: CGFloat` | All SwiftUI | Drives gradient highlight band position |
| `withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false))` | All SwiftUI | Loops shimmer sweep continuously |
| `LinearGradient(stops: [...], startPoint: .leading, endPoint: .trailing)` | All SwiftUI | Creates the moving highlight band |
| `.overlay { ... }` | All SwiftUI | Composites shimmer on top of the loading placeholder |
| `TimelineView(.animation)` | macOS 12+ | Alternative driver if `@State` approach causes animation stutter; `AnimationTimelineSchedule` confirmed available macOS 12+ in SwiftUI swiftinterface |

**Integration pattern:**

Apply a `ShimmerEffect` view modifier to `PopupText(text: requestContext.sourceText, isMuted: true)` inside `LoadingPopupText`. The modifier overlays a gradient with stops `[.clear → .white.opacity(0.4) → .clear]` centered at `shimmerPhase`, which animates from `-0.3` to `1.3` on `.onAppear`. Use `.blendMode(.plusLighter)` for a subtle highlight that works with both light and dark `regularMaterial` backgrounds.

**Do NOT use `.redacted(reason: .placeholder)`.** It renders static grey rectangles with no animation — it is not a shimmer effect.

**Do NOT add third-party shimmer packages** (e.g., `Shimmer` on SwiftPackageIndex). The effect is ~15 lines of SwiftUI; a dependency adds zero value.

---

### Feature 3: Chunked Translation

| API | Framework | Availability | Role |
|-----|-----------|-------------|------|
| `NLTokenizer(unit: .sentence)` | NaturalLanguage | macOS 10.14+ | Splits text at language-aware sentence boundaries |
| `tokenizer.string = text` | NaturalLanguage | macOS 10.14+ | Assigns text to tokenize |
| `tokenizer.enumerateTokens(in:)` | NaturalLanguage | macOS 10.14+ | Block-based iteration over sentence ranges |
| `TranslationSession.translations(from: [Request]) async throws -> [Response]` | Translation | macOS 15+ | **Key API**: translates a batch and returns results in the **same order as input** — no index tracking needed for reassembly. Confirmed in SDK swiftinterface. |
| `TranslationSession.Request(sourceText: String, clientIdentifier: String?)` | Translation | macOS 15+ | One request per chunk; `clientIdentifier` can carry the chunk index for debugging |
| `TranslationSession.Response.targetText` | Translation | macOS 15+ | Translated chunk text to rejoin |

**`translations(from:)` vs `translate(batch:)` — use `translations(from:)`:**
- `translations(from: [Request]) async throws -> [Response]` — awaits all results and returns them in input order. Reassembly is `responses.map(\.targetText).joined(separator: " ")`. Use this.
- `translate(batch: [Request]) -> BatchResponse` — an `AsyncSequence` (yields results as they arrive, potentially out of order). Only useful if streaming partial results into the UI is a future requirement.

**Chunking strategy:**
1. `NLTokenizer` splits text into sentences.
2. Aggregate sentences greedily into chunks ≤ 200 characters.
3. If a single sentence exceeds 200 characters (no boundary found), split at the last whitespace before 200 chars.
4. Pass all chunks as `[TranslationSession.Request]` to `translations(from:)` in one call.
5. Rejoin `response.targetText` values preserving original spacing.

**Where the logic lives:**
- Sentence-splitting and chunk aggregation → new `TextChunker` type in `Transy/Translation/` (pure Foundation + NaturalLanguage, fully unit-testable).
- Batch call → inside `LoadingPopupText.translationAction`, replacing the single `session.translate(requestContext.sourceText)` when text exceeds the chunking threshold.

**New `import NaturalLanguage` required** in `TextChunker.swift` only. No existing files need import changes.

---

## Installation

No new packages. One new framework import:

```swift
// TextChunker.swift (new file)
import NaturalLanguage
import Foundation
```

NaturalLanguage.framework is a system framework bundled with macOS — no SPM dependency, no entitlement required.

---

## Alternatives Considered

| Feature | Recommended | Alternative | Why Not |
|---------|-------------|-------------|---------|
| Pivot detection | Catch `TranslationError.unsupportedLanguagePairing` from session | `LanguageAvailability.status()` preflight | Removed in v0.4.0: causes double ML inference per request. Error-catch is the correct approach. |
| Sentence splitting | `NLTokenizer(unit: .sentence)` | Manual split on `.`, `!`, `?` | Naive punctuation split breaks on abbreviations ("Dr. Smith"), ellipses, and Japanese text (`。` vs `.`). `NLTokenizer` handles all of these correctly. |
| Chunk ordering | `translations(from:) -> [Response]` | `translate(batch:) -> BatchResponse` + clientIdentifier sort | `translations(from:)` guarantees output order matching input order. No sort logic needed. Confirmed in SDK swiftinterface. |
| Shimmer driver | `@State` + `withAnimation(.repeatForever)` | `TimelineView(.animation)` | Both work on macOS 15+. `@State` approach is simpler. `TimelineView` is the fallback if SwiftUI transaction batching causes animation stutter on macOS. |
| Shimmer appearance | Custom `LinearGradient` overlay | `.redacted(reason: .placeholder)` | `.redacted` is a static grey block, not animated. Wrong tool for a shimmer effect. |

---

## What NOT to Add

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| `LanguageAvailability.status()` preflight before each translation | Double ML inference; explicitly removed from v0.4.0 for this reason | Catch `TranslationError.unsupportedLanguagePairing` in the existing error handler |
| Third-party shimmer packages | ~15 lines of SwiftUI covers the full effect; zero dependency value | Custom `ShimmerEffect: ViewModifier` |
| `withTaskGroup` for parallel chunk translation | `translations(from:)` handles parallelism internally; `TaskGroup` would add complexity for no gain | `TranslationSession.translations(from:)` |
| Streaming partial chunk results to UI | Adds a `.partialResult` case to `PopupState`; not worth it for typical clipboard selections | Show shimmer until all chunks complete, then show full result |
| `NLLanguageRecognizer` for pivot language detection | Translation framework with `source: nil` already auto-detects language; adding `NLLanguageRecognizer` duplicates work | Let `source: nil` in `Configuration` handle detection; pivot triggers only on error |
| `TranslationSession.Strategy` (highFidelity/lowLatency) | Requires macOS 26.4 — above the project's macOS 15 floor | Not applicable for v0.5.0 |

---

## Stack Patterns by Feature

**Pivot — error-driven, not preflight-driven:**
Always attempt direct translation first. Pivot is a recovery path, not a planned path. This avoids latency cost of a status check on every request. The existing `TranslationErrorMapper` already identifies unsupported-pair errors — pivot hooks into those same cases.

**Shimmer — loading state only, auto-tears-down:**
Apply `ShimmerEffect` modifier only inside `LoadingPopupText`. SwiftUI's `.id(requestID)` on the loading view already ensures the animation tears down when the view transitions out of `.loading` state. No manual cleanup needed.

**Chunking — threshold guards the fast path:**
Skip chunking entirely for text ≤ 200 characters (the vast majority of clipboard selections). A single `guard text.count > 200 else { return [text] }` at the top of `TextChunker` keeps the common path fast and avoids unnecessary `NLTokenizer` overhead.

---

## Version Compatibility

| API | Introduced | Notes |
|-----|-----------|-------|
| `TranslationSession.translations(from:)` | macOS 15.0 | Returns ordered `[Response]`; confirmed in SDK swiftinterface |
| `TranslationSession.translate(batch:)` | macOS 15.0 | Returns `BatchResponse` (AsyncSequence); out-of-order — do not use for chunking |
| `TranslationSession.Configuration.invalidate()` | macOS 15.0 | Required for pivot leg re-triggering |
| `Locale.Language(languageCode: .english)` | macOS 13.0 | `Locale.LanguageCode.english` is `@_alwaysEmitIntoClient`; confirmed in Foundation swiftinterface |
| `NLTokenizer(unit: .sentence)` | macOS 10.14 | Well below project floor; zero risk |
| `TimelineView(.animation)` | macOS 12.0 | Below project floor; available if needed as shimmer fallback |
| `LinearGradient` + `withAnimation` | macOS 11.0 | Below project floor; available |
| `TranslationSession.Strategy` (highFidelity/lowLatency) | macOS 26.4 | **Do not use** — above the project's macOS 15 floor |

---

## Sources

- `Translation.framework` — `arm64e-apple-macos.swiftinterface` from Xcode SDK (Translation version 365.8.2) — verified all `TranslationSession`, `TranslationError`, `LanguageAvailability` API signatures
- `NaturalLanguage.framework` — `NLTokenizer.h` from Xcode SDK — verified `NLTokenUnit.sentence`, `enumerateTokensInRange:usingBlock:`
- `Foundation.framework` — `arm64e-apple-macos.swiftinterface` from Xcode SDK — verified `Locale.Language(languageCode:)`, `Locale.LanguageCode.english`
- `SwiftUI.framework` — `arm64e-apple-macos.swiftinterface` from Xcode SDK — verified `TimelineView`, `AnimationTimelineSchedule` availability (macOS 12+)
- `.planning/PROJECT.md` — confirmed removal of `LanguageAvailability.status()` preflight in v0.4.0

---
*Stack research for: Transy v0.5.0 — pivot translation, shimmer animation, chunked translation*
*Researched: 2026-04-05*

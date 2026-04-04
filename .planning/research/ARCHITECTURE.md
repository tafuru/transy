# Architecture Research

**Domain:** macOS menu bar utility — selected-text translation
**Researched:** 2026-04-06 (updated for v0.5.0)
**Confidence:** HIGH (existing code direct-read); MEDIUM (Apple Translation multi-session concurrency)

---

## v0.5.0 Integration Research

This section documents the integration design for the three v0.5.0 features against the existing v0.4.0 architecture. It answers: which files to create vs. modify, where each feature's logic lives, build order, and Swift 6 concurrency constraints.

---

### Existing Architecture (v0.4.0 reference)

```text
AppDelegate (@MainActor)
  │  owns: ClipboardMonitor, PopupController, TranslationCoordinator, SettingsStore
  │
  ├─ ClipboardMonitor.start { text → handleTrigger(text:) }
  │
  └─ handleTrigger(text:)
       │  TextNormalization.normalized(text)
       │  translationCoordinator.begin(sourceText:)   → popupState = .loading(requestID, sourceText)
       │  popupController.show(translationCoordinator:, targetLanguage:, onDismiss:)
       └─ on dismiss → translationCoordinator.dismiss()

PopupController (@MainActor)
  │  owns: NSPanel, dismiss monitors, resize observer
  └─ show() → creates PopupView wrapped in NSHostingView
               sets panel.contentView = hostingView

PopupView (SwiftUI struct)
  │  observes: translationCoordinator.popupState (via @Observable)
  ├─ .loading  → LoadingPopupText (owns translationTask + session)
  ├─ .result   → PopupText(translatedText)
  └─ .error    → PopupText(message)

LoadingPopupText (private SwiftUI struct)
  │  @State translationConfiguration: TranslationSession.Configuration?
  ├─ body: PopupText(sourceText, isMuted: true)   ← source text as loading placeholder
  ├─ .onChange(requestID) → nextTranslationConfiguration()
  └─ .translationTask(configuration, action: translationAction)
       └─ translationAction(session):
            try await session.translate(sourceText)
            → onResult / onError callbacks
            → PopupView calls translationCoordinator.finish() / .fail()

TranslationCoordinator (@MainActor @Observable)
  │  State machine: hidden → loading → result/error → hidden
  │  activeRequestID: UUID? (stale-request guard)
  └─ begin / finish / fail / dismiss
```

---

### Feature 1: English Pivot Translation

#### Problem
`TranslationError.unsupportedLanguagePairing` is already caught in `LoadingPopupText.translationAction` and routed to `onError`. For pivot, instead of failing, we need to chain two `TranslationSession` calls: source→English, then English→target.

#### Root constraint: one `.translationTask` per session config
Apple's `.translationTask(configuration:action:)` creates one `TranslationSession` for the configured pair. To do pivot, we need two sessions with different pairs. The mechanism is `configuration.invalidate()`, which already exists (`nextTranslationConfiguration()`) — it causes SwiftUI to tear down the current session and start a new one.

#### Architecture decision: local pivot state in `LoadingPopupText`
Pivot state is a translation engine implementation detail, not a coordinator concern. `TranslationCoordinator` stays unchanged. A new `@MainActor @Observable` helper class `PivotTranslationState` holds the phase and is owned by `LoadingPopupText` via `@State`.

This mirrors the existing pattern: `TranslationCoordinator` is an `@Observable` class owned via `@State` equivalent. `PivotTranslationState` plays the same role for intra-translation pivot phases.

```text
PivotPhase enum (new, in PivotTranslationState.swift):
  .direct                              ← initial state
  .firstLeg                            ← source→EN in progress
  .secondLeg(intermediate: String)     ← EN→target in progress, intermediate cached
```

#### Data flow (pivot enabled)

```text
translationAction called with session configured (source: nil, target: targetLanguage)
  │
  ├─ success → onResult (normal path, no change)
  │
  └─ catch TranslationError.unsupportedLanguagePairing
       │
       └─ await MainActor.run { pivotState.phase = .firstLeg }
            │
            └─ .onChange(pivotState.phase) fires → nextTranslationConfiguration(target: .english)
                 │
                 └─ translationAction called again with session (source: nil, target: English)
                      │
                      ├─ success (intermediate English text)
                      │    └─ await MainActor.run { pivotState.phase = .secondLeg(intermediate) }
                      │         └─ .onChange → nextTranslationConfiguration(target: targetLanguage)
                      │              └─ translationAction called with session (source: English, target: targetLanguage)
                      │                   ├─ translate(intermediate)  ← uses cached intermediate, NOT sourceText
                      │                   └─ success → onResult
                      │
                      └─ failure → onError (pivot leg 1 also failed)
```

#### Integration points

| File | Change |
|------|--------|
| `Transy/Translation/PivotTranslationState.swift` | **NEW** — `@MainActor @Observable final class PivotTranslationState` with `PivotPhase` enum |
| `Transy/Popup/PopupView.swift` | **MODIFY** `LoadingPopupText`: add `@State private var pivotState = PivotTranslationState()`, extend `.onChange` to also react to `pivotState.phase`, extend `translationAction` to accept `onPivotNeeded` callback and dispatch phase transitions |
| `Transy/Translation/TranslationErrorMapper.swift` | **MODIFY** — expose `static func isPivotableError(_ error: any Error) -> Bool` (extracted from existing `.unsupportedLanguagePairing` match in `message(for:)`) |
| `TranslationCoordinator.swift` | **NO CHANGE** |
| `AppDelegate.swift` | **NO CHANGE** |
| `PopupController.swift` | **NO CHANGE** |

#### Swift 6 concurrency notes
- `translationAction` is `nonisolated static` — all `@Sendable` callback closures must route MainActor mutations through `await MainActor.run {}`
- `PivotTranslationState` is `@MainActor`-isolated, so it is `Sendable` as a reference type — safe to capture in `@Sendable` closures
- `PivotPhase` must be `Sendable` — it contains only `String` (Sendable) so it qualifies
- The `translationAction` signature gains one more `@escaping @Sendable` callback param, matching the existing `onResult`/`onError` pattern

#### Risk: Are multiple sequential `.translationTask` invocations safe?
The existing `nextTranslationConfiguration()` + `configuration.invalidate()` mechanism is already used for each new clipboard copy. Pivot reuses the same mechanism for 2-3 consecutive invalidations within a single user trigger. No new framework surface is exercised — confidence HIGH.

---

### Feature 2: Shimmer Animation

#### Problem
During `.loading`, `LoadingPopupText` shows `PopupText(text: sourceText, isMuted: true)` — static muted text. The shimmer replaces or augments this with an animated gradient overlay that signals "translation in progress" more clearly.

#### Architecture decision: isolated view modifier, no state changes
Shimmer is pure visual state: it is "on" whenever `popupState == .loading` and "off" otherwise. No new state is needed in `TranslationCoordinator` or anywhere else — the fact that `LoadingPopupText` is rendered at all is the signal.

```text
ShimmerModifier (new, in ShimmerModifier.swift):
  @State private var animating = false
  body: ZStack {
    content
    shimmerOverlay   ← LinearGradient masked to content shape, animated horizontally
  }
  .onAppear { withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) { animating = true } }
```

The shimmer gradient slides from `startX = -bounds.width` to `endX = +bounds.width` using a phase offset driven by `animating`. On macOS, prefer `Color.white.opacity(0.25)` peak (dark material background from `PopupText` is `.regularMaterial`) — validate on both light and dark menu bar configurations.

#### Integration points

| File | Change |
|------|--------|
| `Transy/Popup/ShimmerModifier.swift` | **NEW** — `ShimmerModifier: ViewModifier` + `View.shimmer()` extension |
| `Transy/Popup/PopupView.swift` | **MODIFY** `LoadingPopupText.body`: add `.shimmer()` modifier on `PopupText(sourceText, isMuted: true)` |
| All other files | **NO CHANGE** |

#### Swift 6 concurrency notes
- `ShimmerModifier` is a pure SwiftUI struct — no actor isolation needed
- `@State` animation is entirely main-thread; no concurrency surface

#### Risk: none — most isolated of the three features

---

### Feature 3: Chunked Translation

#### Problem
Texts > 200 chars may be split into smaller units that the Apple Translation framework handles better. Each chunk must be translated in order, then joined.

#### Architecture decision: new `TextChunker` utility, modify `translationAction`
Chunking is a text preparation concern, parallel to existing `TextNormalization`. It belongs in `Transy/Translation/` as a pure, stateless utility.

```text
TextChunker (new, in TextChunker.swift):
  static func chunks(from text: String, maxLength: Int = 200) -> [String]
    │
    ├─ if text.count <= maxLength → [text]   (fast path, no allocation)
    │
    └─ split at sentence-final punctuation followed by whitespace/end
         boundary chars: 。.!?！？\n (in priority order)
         if a sentence exceeds maxLength alone → split at last word boundary ≤ maxLength
         never split a unicode scalar mid-codepoint
```

`translationAction` in `LoadingPopupText` becomes:
```swift
let chunks = TextChunker.chunks(from: requestContext.sourceText)
let requests = chunks.enumerated().map { idx, chunk in
    TranslationSession.Request(sourceText: chunk, clientIdentifier: String(idx))
}
let responses = try await session.translations(from: requests)
let assembled = responses.map(\.targetText).joined(separator: " ")
await onResult(requestID, sourceText, assembled)
```

Uses the batch API because:
1. Single network/inference round-trip regardless of chunk count — avoids N× latency of sequential `translate()` calls
2. Results are returned as `[Response]` in the same order as the input array — no `clientIdentifier` mapping needed
3. Cleaner, shorter call site

#### Integration with pivot (combined path)
When both pivot and chunking apply (text > 200 chars AND unsupported language pair):
- Leg 1 action: chunks source text into ≤200-char pieces → translates each to English → joins as `intermediateText`
- Leg 2 action: `TextChunker.chunks(from: intermediateText)` → translates each to target → joins as final result
- No special coordination needed: `TextChunker.chunks()` is always called inside `translationAction`, and the action is re-executed for each pivot leg

#### Integration points

| File | Change |
|------|--------|
| `Transy/Translation/TextChunker.swift` | **NEW** — `enum TextChunker` with `static func chunks(from:maxLength:) -> [String]` |
| `Transy/Popup/PopupView.swift` | **MODIFY** `LoadingPopupText.translationAction`: replace single `session.translate(sourceText)` with chunk loop |
| `TextNormalization.swift` | **NO CHANGE** — `TextNormalization.normalized()` runs before chunking in `AppDelegate.handleTrigger()`; chunking happens inside the translation action |
| All other files | **NO CHANGE** |

#### Swift 6 concurrency notes
- `TextChunker` is a pure `enum` with static methods — no actor isolation, fully `Sendable`
- The for-loop `try await session.translate(chunk)` runs in the existing `nonisolated` action closure — no new concurrency surface

#### Risk: sentence-boundary algorithm correctness
Mixed-language text (Japanese + English) needs boundary detection that handles both `。` and `.`. Unicode sentence segmentation via `NaturalLanguage.NLTokenizer(unit: .sentence)` would be more correct than manual punctuation splitting, but adds a framework dependency. Recommend starting with punctuation-based splitting and adding NLTokenizer if edge cases emerge.

---

### Component Summary

#### New files

| File | Purpose | Feature |
|------|---------|---------|
| `Transy/Translation/PivotTranslationState.swift` | `PivotPhase` enum + `@Observable @MainActor` class holding pivot phase | Pivot |
| `Transy/Popup/ShimmerModifier.swift` | Animated shimmer `ViewModifier` + `View.shimmer()` extension | Shimmer |
| `Transy/Translation/TextChunker.swift` | Sentence-boundary chunking utility | Chunked |

#### Modified files

| File | What changes | Features |
|------|-------------|---------|
| `Transy/Popup/PopupView.swift` | `LoadingPopupText`: pivot state, shimmer overlay, chunk loop in action | All 3 |
| `Transy/Translation/TranslationErrorMapper.swift` | Extract `isPivotableError(_:)` from existing logic | Pivot |

#### Unchanged files

| File | Reason |
|------|--------|
| `AppDelegate.swift` | Trigger flow unchanged; all new logic is below coordinator level |
| `PopupController.swift` | NSPanel lifecycle unchanged |
| `TranslationCoordinator.swift` | State machine unchanged; pivot is encapsulated in LoadingPopupText |
| `TextNormalization.swift` | Chunking is separate from normalization |

---

### Build Order

```
1. TextChunker (most independent)
   └─ Pure utility, testable in isolation, no UI surface
   └─ Required by: pivot leg 1+2 actions when combined with long text

2. ShimmerModifier (UI only)
   └─ Zero logic dependencies, zero state changes
   └─ Can be developed + reviewed independently at any time

3. English Pivot (most complex, build last)
   └─ Depends on: TranslationErrorMapper.isPivotableError() (extracted from existing code)
   └─ Depends on: TextChunker existing (for combined pivot+chunked path)
   └─ Integration risk is highest; benefits from having shimmer already in place
      (shimmer continues to work correctly during multi-leg pivot loading state)
```

**Rationale for this order:**
- Chunked translation is functionally independent and its test suite validates `TextChunker` without any Translation framework dependency
- Shimmer is a visual polish feature; shippable by itself; being live before pivot means the UI looks correct during all pivot phases automatically (pivot stays in `.loading` state throughout both legs — shimmer keeps animating correctly)
- Pivot builds on a correct chunked-action and a ready shimmer; its complexity is contained to `LoadingPopupText` + `PivotTranslationState`

---

### Integration Risk Summary

| Risk | Severity | Mitigation |
|------|---------|-----------|
| `TranslationSession` concurrent `translate()` calls undocumented | MEDIUM | Use sequential chunk translation; investigate parallel only if latency is a measured issue |
| Pivot second-leg config invalidation races with user's rapid re-copy | LOW | `activeRequestID` guard in `TranslationCoordinator` already handles stale requests; pivot phase resets on new `requestID` via `.onChange(requestContext.requestID, initial: true)` |
| Shimmer gradient contrast on light vs. dark system appearance | LOW | Test on both; adjust opacity/color of shimmer peak per color scheme |
| Sentence-boundary chunking splits mid-thought | LOW | Use `NLTokenizer(unit: .sentence)` as upgrade path if needed |
| `LoadingPopupText` growing too complex with 3 features | MEDIUM | Consider extracting to `LoadingPopupViewModel` (`@Observable @MainActor`) that encapsulates pivot + chunking logic, leaving `LoadingPopupText` as thin view |

---

## Standard Architecture

### System Overview

```text
User selects text in another app
        │
        ▼
System-wide trigger monitor
        │
        ▼
Clipboard capture + restore guard
        │
        ▼
TranslationCoordinator
   ┌────┴─────────────┐
   ▼                  ▼
TranslationPopup   TranslationService (protocol)
   │                  │
   │                  └── AppleTranslationClient
   │
   ▼
SettingsStore / model availability guidance
```

The architecture should stay simple: AppKit owns system-integration surfaces, SwiftUI owns rendering, and one coordinator manages the end-to-end translation loop.

### Component Responsibilities

| Component | Responsibility | Communicates With |
|-----------|----------------|-------------------|
| **AppDelegate / App root** | App entry, activation policy, top-level wiring | All top-level components |
| **MenuBarController** | Menu bar presence, menu actions, settings/quit entry points | Settings window, app lifecycle |
| **TriggerMonitor** | Detects the double-`Command+C` gesture using the validated monitoring strategy | ClipboardCapture / Coordinator |
| **ClipboardCapture** | Reads the selected text after a safe delay and restores previous clipboard contents | TriggerMonitor, Coordinator |
| **TranslationCoordinator** | Orchestrates popup presentation, translation requests, cancellation, and result routing | Popup, TranslationService, SettingsStore |
| **TranslationPopupController** | Owns `NSPanel` lifecycle and presentation | Coordinator |
| **TranslationPopupView** | Renders loading/result/error states in SwiftUI | PopupController / Coordinator |
| **TranslationService** | Abstract translation interface | Coordinator |
| **AppleTranslationClient** | Uses Apple's Translation framework for on-device translation | TranslationService |
| **SettingsStore** | Persists target language and tracks model-availability related preferences/state | Settings UI, TranslationService |
| **SettingsWindowController** | Presents settings UI without changing the app's ambient utility behavior | MenuBarController, SettingsStore |

---

## Recommended Project Structure

```text
Transy/
├── App/
│   ├── TransyApp.swift
│   └── AppDelegate.swift
├── MenuBar/
│   └── MenuBarController.swift
├── Trigger/
│   ├── TriggerMonitor.swift
│   ├── DoublePressDetector.swift
│   └── ClipboardCapture.swift
├── Translation/
│   ├── TranslationCoordinator.swift
│   ├── TranslationService.swift
│   └── AppleTranslationClient.swift
├── Popup/
│   ├── TranslationPopupController.swift
│   └── TranslationPopupView.swift
├── Settings/
│   ├── SettingsStore.swift
│   ├── SettingsWindowController.swift
│   └── SettingsView.swift
└── Resources/
    ├── Assets.xcassets
    └── Info.plist
```

### Structure Rationale

- Keep **trigger logic** isolated from UI so timing and permission behavior can be tested/refined independently.
- Keep **translation behind a protocol** so future provider fallback is possible without coordinator refactoring.
- Keep **popup** and **settings** separate because they are different window types with different lifecycle rules.
- Keep **AppKit ownership at the edges** and **SwiftUI inside the windows/panels**.

---

## Architectural Patterns

### Pattern 1: Non-Activating Panel for the Popup

Use `NSPanel` instead of a normal `NSWindow` so the popup can appear without activating the Transy app.

**Why:** this preserves the user's reading flow in the source app.

### Pattern 2: Trigger Abstraction Before API Commitment

Do not bake a single monitoring API into the entire design before Phase 1 validation. Keep a small abstraction boundary:

- detect gesture
- confirm permissions/state
- request clipboard capture
- notify coordinator

This reduces risk if the initial monitoring approach needs to change.

### Pattern 3: Coordinator Owns the State Machine

The end-to-end flow should be coordinated centrally:

1. receive source text
2. show popup immediately in loading state
3. request translation asynchronously
4. apply result or error only if the request is still current

This keeps popup rendering simple and avoids race-condition bugs.

### Pattern 4: Translation Service Protocol

Even though v1 uses Apple Translation only, define:

```swift
protocol TranslationService {
    func translate(_ text: String, targetLanguage: TargetLanguage) async throws -> String
}
```

That keeps external-provider fallback possible later without changing popup/coordinator code.

---

## Data Flow

### Primary Translation Flow

```text
Double Cmd+C detected
    │
    ▼
Validate permission state for chosen monitoring approach
    │
    ▼
Wait for safe clipboard-read timing
    │
    ▼
Capture selected text + snapshot previous clipboard contents
    │
    ▼
Show popup with source text in loading state
    │
    ▼
Call AppleTranslationClient.translate(...)
    │
    ├── success → replace loading state with translated text
    └── failure / missing model → show readable error or guidance state
    │
    ▼
Restore previous clipboard contents
```

### Settings Flow

```text
Menu bar → Settings
    │
    ▼
SettingsWindowController opens settings UI
    │
    ▼
User changes target language
    │
    ▼
SettingsStore persists choice
    │
    ▼
TranslationCoordinator / TranslationService reads updated target language
```

---

## Build Order Implications

1. **App Shell first** — menu bar presence, LSUIElement, activation policy, and window ownership must exist before any feature work.
2. **Trigger + Popup second** — this is where the user-facing UX either feels right or wrong.
3. **Translation integration third** — plug the Apple backend into the already-correct popup workflow.
4. **Settings fourth** — target-language control and model guidance make the app configurable once the core loop exists.

---

## Open Questions to Validate During Planning

- Which monitoring approach best balances reliability, permission burden, and distribution goals for the double-`Command+C` gesture?
- Is a fixed popup position acceptable for v1, or does popup placement need additional work before implementation?
- Is plain `UserDefaults` enough for the first settings pass, or is `Defaults` justified immediately?

---

## Sources

- Apple Developer Documentation: Translation framework
- Apple Developer Documentation: `NSPanel`, `NSStatusItem`, `NSEvent.addGlobalMonitorForEvents`
- WWDC24: Meet the Translation API

---
*Architecture research for: macOS menu bar selected-text translation utility (Transy)*
*Researched: 2026-03-14*

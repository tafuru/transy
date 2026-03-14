# Phase 3: Translation Loop - Research

**Researched:** 2026-03-14
**Domain:** Apple Translation framework integration inside an AppKit-hosted SwiftUI popup on macOS 15+
**Confidence:** MEDIUM

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Default Target Language
- Phase 3 uses a fixed default target language of English until Phase 4 settings exist.
- Treat that default as generic English rather than a region-specific variant.
- Do not add extra in-app messaging about the temporary English default; README / PR communication is enough for now.
- If the source text is already English, it is acceptable for the resulting output to still be English rather than showing a special same-language message.

#### Failure Presentation
- If translation fails, keep the popup open and show a short inline error message instead of dismissing silently.
- For missing-model / unavailable-pair cases, the message should be slightly explicit rather than fully generic.
- Error state remains visible until the user dismisses the popup with `Escape` or outside click.
- Error copy should stay short and matter-of-fact rather than verbose or instructional.

#### Loading Presentation
- Keep the current muted source-text loading treatment in Phase 3; do not add shimmer, spinner, or ellipsis.
- If translation takes longer than expected, keep the same quiet loading appearance rather than escalating the visual treatment.
- Keep the popup compact during loading; long source text should still favor truncation over aggressive expansion.
- When translation completes, replace the loading state almost instantly rather than using a noticeable transition animation.

#### Re-trigger and Cancellation Behavior
- If the user triggers translation again while a request is in flight, prioritize the new selection and cancel the older request.
- Reuse the same popup and swap immediately to the newly captured source text while the replacement translation starts.
- If the popup is dismissed while translation is in flight, cancel the in-progress request immediately.
- Any stale result that arrives from an older or cancelled request must be ignored and must never overwrite the currently active request.

### Claude's Discretion
- Exact wording of the non-model error copy as long as it stays short and matter-of-fact.
- Exact state-model shape (`enum`, view model, coordinator object) used to drive loading / result / error transitions.
- Exact cancellation/token mechanism used to prevent stale results from rendering.
- Exact source-text normalization rules before sending text into the Translation framework.

### Deferred Ideas (OUT OF SCOPE)
- Animated skeleton / shimmer loading remains a later UI refinement if the quiet muted treatment feels too subtle.
- Target-language selection and persistence belong to Phase 4.
- User guidance for downloading or managing translation models belongs to Phase 4's settings/model-management work.
- Any special-case UX for "source is already English" is deferred; same-language output is acceptable in Phase 3.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| TRAN-01 | User receives an on-device Apple Translation framework translation of the selected text into the configured target language | Use `TranslationSession` via SwiftUI `.translationTask(...)` hosted inside `PopupView`; target is fixed to generic English; preflight `LanguageAvailability.status(for:to:)` gates missing-model and unsupported cases before translation |
| TRAN-02 | User does not need to choose the source language manually; the source language is detected automatically | Pass `source: nil` to the translation session, but run `LanguageAvailability.status(for:to:)` first so ambiguous detection becomes an inline error instead of triggering framework UI |
| TRAN-03 | User sees the translated text replace the loading placeholder in the same popup when translation completes | Drive the popup from a request-scoped state machine (`.loading → .result | .error`) and guard all result/error writes with an active-request token so stale completions never overwrite the visible popup |
</phase_requirements>

---

## Summary

The important architectural fact for this phase is that Apple’s Translation framework is not a simple “call this service from `AppDelegate`” API on the macOS 15 deployment floor. For automatic source-language detection, the standard API surface is SwiftUI’s `.translationTask(...)`, which hands a `TranslationSession` to a view. Current Apple docs also warn that using a `TranslationSession` after the attached view disappears or after the configuration changes causes a `fatalError`. That makes `PopupView` — not `AppDelegate` — the correct home for the actual `session.translate(...)` call.

The other major trap is model/download behavior. `TranslationSession.translate(_:)` may show system UI to download languages, and if `sourceLanguage` is `nil` it may also prompt the user to choose a source language when detection is unclear. That conflicts with this phase’s locked scope: no source-language picker, no model-management UI, and inline errors instead of surprise framework UI. The right pattern is to preflight every request with `LanguageAvailability.status(for:to:)`. Only proceed to translation when status is `.installed`; map `.supported` and `.unsupported` to short inline errors in the existing popup.

This phase should therefore be planned as a request-scoped popup state machine: trigger shows muted source text immediately, preflight availability/detection, run translation in `PopupView.translationTask`, then publish `.result` or `.error` only if the request token still matches the currently visible popup. Dismissal and re-trigger should invalidate the request token and tear down the old view/session so older completions cannot render stale output.

**Primary recommendation:** Keep translation execution view-scoped in `PopupView.translationTask`, add `LanguageAvailability` preflight before every translation, and use a `@MainActor` request token/state machine to prevent stale results after re-trigger or dismiss.

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `Translation` framework | macOS 15+ system framework | On-device translation | Apple-native, on-device, no network dependency, already chosen in project state |
| `SwiftUI.View.translationTask(source:target:action:)` | macOS 15+ | Obtain a `TranslationSession` with automatic source detection | Official path for unknown-source translation on the current deployment floor |
| `LanguageAvailability` | macOS 15+ | Check installed/supported/unsupported status for detected source → target pair | Prevents unwanted framework download/source-picker UI and gives a clean inline error path |
| `NSHostingView` inside existing `NSPanel` | macOS 15+ | Host translation-capable SwiftUI popup content in the Phase 2 popup | Reuses the existing popup architecture without focus changes |
| `Observation` / `@Observable` + `@MainActor` coordinator | Swift 6 / Xcode 16 | Drive `.loading → .result | .error` transitions safely on the main actor | Matches existing `AppState` style and keeps UI updates race-safe |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `TranslationSession.Configuration` | macOS 15+ | Trigger or invalidate a SwiftUI translation task | Use when the popup view persists and you need to rerun translation with new content |
| `Task` / structured concurrency | Swift 6 | Sequence preflight + translate work and cancel by view teardown/request invalidation | Use for async orchestration around trigger and dismiss |
| `Locale.Language(identifier: "en")` | Foundation / macOS 15+ | Fixed generic-English target until Phase 4 settings exist | Use as the single target-language source of truth for this phase |
| `Swift Testing` | Xcode 16 | Unit-test coordinator/state/race logic | Use for fast deterministic tests around tokens, error mapping, and state transitions |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `PopupView.translationTask(...)` | `TranslationSession(installedSource:target:)` in a service | Direct non-UI init is only available in macOS 26+ in the current SDK, so it cannot be the standard path for this app’s macOS 15 floor |
| `LanguageAvailability.status(for:to:)` preflight | Call `session.translate(...)` immediately | Blind translate can trigger system download UI or a source-language picker, which violates Phase 3 scope |
| Request token + state guard | “Last task wins” by hope/cancellation alone | Cancellation timing is not enough; stale completions must still be ignored defensively |
| Manual language heuristics | `NLLanguageRecognizer` or custom detection | Duplicates framework behavior, adds ambiguity, and still does not solve model-availability checks |

**Installation:** No SPM package or `project.yml` dependency change. Use system frameworks only:

```swift
import Translation
import SwiftUI
```

---

## Architecture Patterns

### Recommended Project Structure

```text
Transy/
├── AppDelegate.swift                  # trigger entry point; starts popup session
├── AppState.swift                     # shared popup/request state
├── Popup/
│   ├── PopupController.swift          # owns single NSPanel, dismissal callback, root NSHostingView
│   └── PopupView.swift                # renders loading/result/error and runs translationTask
├── Translation/
│   ├── TranslationCoordinator.swift   # @MainActor state machine + request token
│   ├── TranslationAvailabilityClient.swift  # wraps LanguageAvailability preflight
│   ├── TranslationErrorMapper.swift   # maps framework errors/statuses to short inline copy
│   └── TextNormalization.swift        # trim/minimal whitespace normalization helpers
└── Trigger/
    └── ClipboardRestoreSession.swift  # unchanged; remains orthogonal to translation
```

> `project.yml` needs no update: `sources: path: Transy` already picks up new Swift files recursively.

### Pattern 1: Request-Scoped Popup State Machine
**What:** Model popup content as request-bound state instead of directly swapping raw strings. Every trigger gets a fresh `requestID`; only the active request may write `.result` or `.error`.

**When to use:** Always. This is the simplest way to satisfy stale-result handling, dismiss cancellation, and same-popup replacement.

**Example:**

```swift
// Source: project code pattern (`AppState` is already @Observable) + Apple docs for translationTask lifecycle
@MainActor
@Observable
final class TranslationCoordinator {
    enum PopupState: Equatable {
        case hidden
        case loading(requestID: UUID, sourceText: String)
        case result(requestID: UUID, sourceText: String, translatedText: String)
        case error(requestID: UUID, sourceText: String, message: String)
    }

    private(set) var activeRequestID: UUID?
    var popupState: PopupState = .hidden

    func begin(sourceText: String) -> UUID {
        let requestID = UUID()
        activeRequestID = requestID
        popupState = .loading(requestID: requestID, sourceText: sourceText)
        return requestID
    }

    func finish(requestID: UUID, sourceText: String, translatedText: String) {
        guard activeRequestID == requestID else { return }
        popupState = .result(
            requestID: requestID,
            sourceText: sourceText,
            translatedText: translatedText
        )
    }

    func fail(requestID: UUID, sourceText: String, message: String) {
        guard activeRequestID == requestID else { return }
        popupState = .error(requestID: requestID, sourceText: sourceText, message: message)
    }

    func dismiss() {
        activeRequestID = nil
        popupState = .hidden
    }
}
```

### Pattern 2: Preflight Availability Before Translating
**What:** Run `LanguageAvailability.status(for:to:)` using normalized sample text before starting translation. Only translate when status is `.installed`.

**When to use:** For every Phase 3 request. This is the cleanest way to enforce automatic detection without user prompts and to surface missing-model errors inline.

**Example:**

```swift
import Foundation
import Translation

// Source: https://developer.apple.com/documentation/translation/languageavailability
// Source: https://developer.apple.com/documentation/translation/languageavailability/status(for:to:)
@MainActor
final class TranslationAvailabilityClient {
    private let availability = LanguageAvailability()
    private let targetLanguage = Locale.Language(identifier: "en")

    enum PreflightResult: Equatable {
        case ready
        case unavailable(message: String)
    }

    func preflight(sampleText: String) async -> PreflightResult {
        do {
            let status = try await availability.status(for: sampleText, to: targetLanguage)
            switch status {
            case .installed:
                return .ready
            case .supported:
                return .unavailable(message: "Translation model not installed.")
            case .unsupported:
                return .unavailable(message: "This language pair isn’t supported.")
            }
        } catch TranslationError.unableToIdentifyLanguage {
            return .unavailable(message: "Couldn't detect the source language.")
        } catch {
            return .unavailable(message: "Translation failed.")
        }
    }
}
```

### Pattern 3: View-Scoped Translation Execution
**What:** Run the actual `session.translate(...)` inside `PopupView.translationTask(...)`. Do not store the session on a service or call it after the view disappears.

**When to use:** On the visible popup content only.

**Example:**

```swift
import SwiftUI
import Translation

// Source: https://developer.apple.com/documentation/swiftui/view/translationtask(source:target:action:)
// Source: https://developer.apple.com/documentation/translation/translationsession
struct PopupView: View {
    let requestID: UUID
    let sourceText: String
    let targetLanguage = Locale.Language(identifier: "en")
    @Bindable var coordinator: TranslationCoordinator

    var body: some View {
        popupContent
            .translationTask(source: nil, target: targetLanguage) { session in
                guard coordinator.activeRequestID == requestID else { return }
                do {
                    let response = try await session.translate(sourceText)
                    await MainActor.run {
                        coordinator.finish(
                            requestID: requestID,
                            sourceText: sourceText,
                            translatedText: response.targetText
                        )
                    }
                } catch is CancellationError {
                    // Ignore view teardown / retrigger cancellation.
                } catch {
                    await MainActor.run {
                        coordinator.fail(
                            requestID: requestID,
                            sourceText: sourceText,
                            message: TranslationErrorMapper.message(for: error)
                        )
                    }
                }
            }
    }

    @ViewBuilder
    private var popupContent: some View {
        // existing muted-loading / result / error rendering
    }
}
```

### Pattern 4: Minimal Normalization, Not Heavy Rewriting
**What:** Normalize only enough to avoid empty/garbage requests and improve detection quality: trim surrounding whitespace/newlines, collapse obvious repeated spaces for the detection sample, and preserve the user’s text content for translation.

**When to use:** Immediately after clipboard capture and before `begin(...)`.

**Example:**

```swift
import Foundation

func normalizedSourceText(_ raw: String) -> String {
    raw.trimmingCharacters(in: .whitespacesAndNewlines)
}

func detectionSample(from text: String) -> String {
    text
        .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        .trimmingCharacters(in: .whitespacesAndNewlines)
}
```

### Anti-Patterns to Avoid
- **Calling `TranslationSession(installedSource:target:)` as the main Phase 3 path:** Verified against the current SDK, that initializer is macOS 26+ only.
- **Calling `session.translate(...)` blindly without preflight:** Can trigger framework UI for downloads or unclear source detection.
- **Storing `TranslationSession` on a coordinator/service:** Apple docs say using a session after the view disappears or configuration changes causes a `fatalError`.
- **Relying on cancellation alone to prevent stale UI:** Always guard writes with `requestID == activeRequestID`.
- **Aggressively rewriting copied text:** Translation quality suffers if paragraphs/punctuation are heavily altered just to “clean up” clipboard content.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Source-language detection | Custom heuristics with `NLLanguageRecognizer` or regexes | `LanguageAvailability.status(for:to:)` + `TranslationSession` auto-detection | The framework already couples detection with language-pair availability; custom detection still leaves model-status unknown |
| Translation backend | HTTP client / external API / custom model fallback | Apple `Translation` framework only | Requirement is explicitly on-device and Phase 4 defers provider choices |
| Missing-model discovery | Filesystem probes / private framework guesses | `LanguageAvailability.Status` | Official API already tells you `.installed`, `.supported`, or `.unsupported` |
| Race handling | Sleep-based debouncing or “cancel and hope” | Request token + state guard + view teardown | Async completion order is nondeterministic; explicit guards are cheap and reliable |
| Error copy | Raw `localizedDescription` passthrough | Small app-owned mapper for known statuses/errors | System strings can be verbose, inconsistent, or availability-gated by OS version |

**Key insight:** The deceptively hard part of this phase is not the translation call itself; it is controlling lifecycle, downloads, and stale updates around Apple’s view-scoped session model.

---

## Common Pitfalls

### Pitfall 1: Blind `translate(_:)` Shows Framework UI
**What goes wrong:** The app unexpectedly prompts for language downloads or source-language choice instead of staying in the existing popup.

**Why it happens:** Apple’s `translate(_:)` docs explicitly say the framework may ask to download languages and may prompt for a source language when `sourceLanguage` is `nil` and detection is unclear.

**How to avoid:** Preflight with `LanguageAvailability.status(for:to:)`. Only call `translate(_:)` when status is `.installed`.

**Warning signs:** Translation sometimes works instantly on one Mac but shows unrelated system UI on a fresh machine or a language pair with no installed assets.

### Pitfall 2: Using `TranslationSession` Outside View Lifetime
**What goes wrong:** Crashes or undefined behavior when re-triggering or dismissing the popup during translation.

**Why it happens:** Apple documents that using a session after the attached view disappears or after the configuration changes causes a `fatalError`.

**How to avoid:** Keep `session.translate(...)` inside `PopupView.translationTask(...)`. Do not store the session on a service or detached long-lived task.

**Warning signs:** A stored session property, nested detached tasks, or attempts to reuse one session instance across multiple popup requests.

### Pitfall 3: Planning Around APIs That Aren’t Available on macOS 15
**What goes wrong:** The plan assumes direct non-UI session init, `session.cancel()`, or `TranslationError.notInstalled`, then hits compiler availability errors.

**Why it happens:** The current SDK exposes those conveniences only on macOS 26+, while the app’s deployment target is macOS 15.0.

**How to avoid:** Treat `.translationTask(...)` + `LanguageAvailability` as the baseline Phase 3 API set.

**Warning signs:** Compiler errors mentioning macOS 26.0 on `init(installedSource:target:)`, `cancel()`, or `TranslationError.notInstalled`.

### Pitfall 4: Short Text Makes Auto-Detection Fragile
**What goes wrong:** Very short or noisy selections fail detection, even though longer text works.

**Why it happens:** Apple’s `status(for:to:)` docs recommend sample text of at least 20 characters for best automatic detection.

**How to avoid:** Normalize the detection sample, keep failure copy short, and test short Japanese/English snippets explicitly during manual smoke.

**Warning signs:** One-word selections, punctuation-only selections, or copied fragments with mostly whitespace.

### Pitfall 5: Stale Result Overwrites Newer Popup Content
**What goes wrong:** A slower earlier request finishes after a newer trigger and replaces the popup with the wrong translation.

**Why it happens:** Async completion order is nondeterministic, especially when one request hits model checks or slower language processing.

**How to avoid:** Generate a new request token per trigger, clear it on dismiss, and guard every success/error write.

**Warning signs:** Rapid double-trigger smoke tests occasionally show the first selection’s result after the second popup is already visible.

---

## Code Examples

Verified patterns from official sources:

### Automatic detection + installed-only gate

```swift
import Foundation
import Translation

// Source: https://developer.apple.com/documentation/translation/languageavailability/status(for:to:)
let availability = LanguageAvailability()
let target = Locale.Language(identifier: "en")
let status = try await availability.status(for: sampleText, to: target)

switch status {
case .installed:
    // safe to proceed with translation in Phase 3
case .supported:
    // show inline "Translation model not installed."
case .unsupported:
    // show inline "This language pair isn’t supported."
}
```

### SwiftUI translation task in the popup

```swift
import SwiftUI
import Translation

// Source: https://developer.apple.com/documentation/swiftui/view/translationtask(source:target:action:)
Text(displayText)
    .translationTask(source: nil, target: .init(identifier: "en")) { session in
        let response = try await session.translate(sourceText)
        await MainActor.run {
            displayText = response.targetText
        }
    }
```

### Config invalidation when a persistent view reruns translation

```swift
import Translation

// Source: https://developer.apple.com/documentation/translation/translationsession/configuration
@State private var configuration = TranslationSession.Configuration(
    source: nil,
    target: .init(identifier: "en")
)

func rerunForNewSourceText() {
    configuration.invalidate()
}
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Treat Translation as a plain service API from AppDelegate | On macOS 15, automatic-detection translation is most safely view-scoped via SwiftUI `.translationTask(...)` | Verified in current Apple docs + current SDK interface | Plan around `PopupView` owning translation execution, not a detached client |
| Let `translate(_:)` manage downloads/source selection | Preflight with `LanguageAvailability` and keep Phase 3 UI inline-only | Current Apple docs for `translate(_:)` and locked Phase 3 scope | Avoid surprise framework UI and keep Phase 4 model management deferred |
| Depend on `TranslationSession(installedSource:target:)`, `cancel()`, or `TranslationError.notInstalled` | Assume those are newer-OS conveniences, not baseline APIs for this project | Verified against current `Translation.swiftinterface` and `swiftc -typecheck` on macOS 15 target | Do not build the plan around APIs that won’t compile for the deployment target |

**Deprecated/outdated:**
- **Pure non-UI TranslationSession planning for unknown-source translation on macOS 15:** outdated for this app’s deployment floor; use the view-scoped session path.
- **Relying on system prompts for missing models/source choice:** outdated for this phase’s UX constraints; show inline errors instead.

---

## Open Questions

1. **How often does `status(for:to:)` succeed while `translate(_:)` still prompts on the same content?**
   - What we know: Apple documents preflight detection and installed/supported/unsupported states, but does not explicitly guarantee identical behavior for every later translation call.
   - What's unclear: Whether some borderline samples still reach source-choice UI during `translate(_:)`.
   - Recommendation: Add a manual smoke step on a macOS 15 machine with short/ambiguous text and a fresh language-model state before calling Phase 3 done.

2. **Should result/error states keep the same 4-line truncation as loading, or loosen slightly after translation finishes?**
   - What we know: Context locks compact loading and quiet visuals, but does not fully specify finished-state height policy.
   - What's unclear: Whether translated output should remain capped identically or allow a modest expansion.
   - Recommendation: Keep Phase 3 conservative: same compact frame first, revisit output density only if manual validation shows unreadable results.

3. **How much normalization helps detection without harming meaning for copied multiline text?**
   - What we know: Trim + light whitespace cleanup is safe; aggressive rewriting is risky.
   - What's unclear: Whether copied PDF/web text needs paragraph flattening for better detection in practice.
   - Recommendation: Plan minimal normalization first, then validate with real Japanese/English source selections during smoke testing.

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Swift Testing (unit) + XCTest (placeholder UI target), via Xcode 16 / Swift 6 |
| Config file | none — default Xcode test targets in `Transy.xcodeproj` generated from `project.yml` |
| Quick run command | `xcodebuild test -project Transy.xcodeproj -scheme Transy -destination 'platform=macOS' -only-testing:TransyTests` |
| Full suite command | `xcodebuild test -project Transy.xcodeproj -scheme Transy -destination 'platform=macOS'` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| TRAN-01 | Installed on-device translation path moves popup from loading to result | unit + manual smoke | `xcodebuild test -project Transy.xcodeproj -scheme Transy -destination 'platform=macOS' -only-testing:TransyTests/TranslationCoordinatorTests` | ❌ Wave 0 |
| TRAN-02 | Source language is auto-detected; ambiguous or unavailable cases become inline errors without prompting settings/UI | unit + manual smoke | `xcodebuild test -project Transy.xcodeproj -scheme Transy -destination 'platform=macOS' -only-testing:TransyTests/TranslationAvailabilityClientTests` | ❌ Wave 0 |
| TRAN-03 | Same popup swaps `.loading` to `.result` and ignores stale completions after re-trigger/dismiss | unit | `xcodebuild test -project Transy.xcodeproj -scheme Transy -destination 'platform=macOS' -only-testing:TransyTests/TranslationRaceGuardTests` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `xcodebuild test -project Transy.xcodeproj -scheme Transy -destination 'platform=macOS' -only-testing:TransyTests`
- **Per wave merge:** `xcodebuild test -project Transy.xcodeproj -scheme Transy -destination 'platform=macOS'`
- **Phase gate:** Full suite green plus manual smoke on a macOS 15 device with at least one installed supported pair and one missing/unsupported case before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `TransyTests/TranslationAvailabilityClientTests.swift` — covers TRAN-02 preflight status mapping (`.installed`, `.supported`, `.unsupported`, ambiguous detection)
- [ ] `TransyTests/TranslationCoordinatorTests.swift` — covers TRAN-01/03 state machine transitions (`loading → result`, `loading → error`, dismiss reset)
- [ ] `TransyTests/TranslationRaceGuardTests.swift` — covers stale-success/stale-error suppression when request IDs change
- [ ] A fake translation runner seam for tests — lets unit tests simulate success/failure without requiring Apple language assets in CI

---

## Sources

### Primary (HIGH confidence)
- Apple Developer Documentation — `TranslationSession`: https://developer.apple.com/documentation/translation/translationsession
- Apple Developer Documentation — `TranslationSession.translate(_:)`: https://developer.apple.com/documentation/translation/translationsession/translate(_:)-4m20l
- Apple Developer Documentation — `TranslationSession.Configuration`: https://developer.apple.com/documentation/translation/translationsession/configuration
- Apple Developer Documentation — `LanguageAvailability`: https://developer.apple.com/documentation/translation/languageavailability
- Apple Developer Documentation — `LanguageAvailability.status(for:to:)`: https://developer.apple.com/documentation/translation/languageavailability/status(for:to:)
- Apple Developer Documentation — `TranslationError`: https://developer.apple.com/documentation/translation/translationerror
- Apple Developer Documentation — `translationTask(_:action:)`: https://developer.apple.com/documentation/swiftui/view/translationtask(_:action:)
- Apple Developer Documentation — `translationTask(source:target:action:)`: https://developer.apple.com/documentation/swiftui/view/translationtask(source:target:action:)
- Local SDK interface — `/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.2.sdk/System/Library/Frameworks/Translation.framework/Versions/A/Modules/Translation.swiftmodule/arm64e-apple-macos.swiftinterface` (verified availability of `TranslationSession`, `cancel()`, and `TranslationError` members)
- Local SDK interface — `/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.2.sdk/System/Library/Frameworks/_Translation_SwiftUI.framework/Versions/A/Modules/_Translation_SwiftUI.swiftmodule/arm64e-apple-macos.swiftinterface` (verified SwiftUI `translationTask` signatures)

### Secondary (MEDIUM confidence)
- None

### Tertiary (LOW confidence)
- None

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - official Apple docs and local SDK interfaces agree on the core API surface
- Architecture: MEDIUM - the view-scoped session pattern is well-supported, but exact runtime behavior around ambiguous short text still needs manual validation
- Pitfalls: HIGH - direct documentation and SDK availability checks clearly expose the main failure modes

**Research date:** 2026-03-14
**Valid until:** 2026-04-13

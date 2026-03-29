# SwiftUI Translation Model Download UI

**Researched:** 2025-01-20
**Confidence:** HIGH (verified via Apple developer documentation JSON APIs)

## Overview

Apple's Translation framework (iOS 17.4+ / macOS 14.4+ for the overlay, iOS 18+ / macOS 15+ for the full programmatic API) provides **built-in SwiftUI modifiers** that handle language model download prompts automatically. When a translation is requested and the required model isn't installed, the framework presents a system UI asking the user to approve the download — no need to send users to System Settings manually.

Transy already uses `.translationTask()` in its `PopupView.swift` — it's halfway there. The missing piece is leveraging `prepareTranslation()` or the system's automatic download prompt instead of manually checking `LanguageAvailability.status` and showing a "go to System Settings" guidance.

## How It Works

### The Two SwiftUI Translation Modifiers

#### 1. `.translationPresentation(isPresented:text:...)` — System Translation Overlay
- **Available:** iOS 17.4+ / macOS 14.4+
- **Purpose:** Shows Apple's built-in translation popover UI (same as Safari's Translate feature)
- **What it looks like:** A system-provided popover/sheet that shows source text, detected language, translated text, and a "Replace with Translation" button
- **Model downloads:** If the model isn't installed, the system automatically prompts the user to download it within this popover
- **Customization:** Minimal — you control `isPresented`, `text`, `attachmentAnchor`, `arrowEdge`, and an optional `replacementAction` closure
- **Limitation:** "Works best with short strings (no more than a couple of sentences or phrases in length)" per Apple docs
- **NOT recommended for Transy** — this replaces the entire translation UI with Apple's system popover, removing Transy's custom popup experience

```swift
// Apple's system translation overlay
.translationPresentation(
    isPresented: $showTranslation,
    text: sourceText,
    replacementAction: { translatedText in
        self.result = translatedText
    }
)
```

#### 2. `.translationTask(_:action:)` — Programmatic Translation with Auto-Download
- **Available:** iOS 18.0+ / macOS 15.0+ (the version Transy targets)
- **Purpose:** Provides a `TranslationSession` for custom translation logic
- **Model downloads:** When the session is used and models aren't installed, **the framework automatically prompts the user to download them** — this is the key finding
- **Customization:** Full control — you get a `TranslationSession` and can translate however you want
- **Already used by Transy:** `PopupView.swift` line 139 uses `.translationTask(translationConfiguration, action: ...)`

### TranslationSession.Configuration

This is the configuration object Transy already uses. Key properties:

```swift
struct Configuration {
    var source: Locale.Language?  // nil = auto-detect
    var target: Locale.Language
    var preferredStrategy: TranslationSession.Strategy?

    mutating func invalidate()   // Re-runs the translation with same languages
    var version: Int { get }     // Increments on invalidate
}
```

Two initializers:
- `init(source:target:)` — basic
- `init(source:target:preferredStrategy:)` — with strategy control

### The `prepareTranslation()` Method — Proactive Download Prompt

This is the critical API for showing download UI proactively:

```swift
// On TranslationSession (obtained via .translationTask)
func prepareTranslation() async throws
```

**What it does:**
- If models for the session's `sourceLanguage` and `targetLanguage` are already installed → returns immediately, no UI shown
- If models are downloading → returns immediately, no UI shown
- If models need to be downloaded → **presents a system dialog asking the user for permission to download**
- If `sourceLanguage` is `nil` → throws an error (can't prepare without knowing the source language)

**This is the "download instruction/progress view" the user is looking for.** When called, the system shows a sheet/dialog that:
1. Explains which language pair needs to be downloaded
2. Shows a "Download" button for user consent
3. Handles the download progress internally
4. Returns when the download is complete (or throws if user cancels)

### Checking Model Availability Programmatically

Transy already does this via `LanguageAvailability`:

```swift
let availability = LanguageAvailability()

// With explicit source and target
let status = try await availability.status(from: source, to: target)

// With text-based source detection
let status = try await availability.status(for: sampleText, to: target)
```

`LanguageAvailability.Status` has three cases:
- `.installed` — model is downloaded and ready
- `.supported` — model is available but not downloaded
- `.unsupported` — language pair is not supported

### `TranslationSession.isReady` and `canRequestDownloads`

```swift
// On TranslationSession:
var isReady: Bool { get async }      // Checks if translation will succeed
var canRequestDownloads: Bool { get } // Whether this session can show download prompts
```

Per Apple docs:
- `isReady`: "In a session that can request downloads, it prompts the person to approve downloads if languages aren't ready yet."
- `canRequestDownloads`: "If true, the system prompts the person to authorize downloading additional languages if they aren't already installed. If false, the session throws `TranslationError` if you attempt to translate without installed languages."

**Key insight:** A session obtained via `.translationTask()` **can** request downloads. A session created manually via `TranslationSession.init(installedSource:target:)` **cannot** — it requires pre-installed models.

## What Transy Currently Does vs What It Could Do

### Current Approach (Manual Guidance)

```
User copies text → .translationTask fires → preflight checks LanguageAvailability.status
  → If .missingModel → shows error message "Model not installed"
  → Settings page has "Open Language & Region" button → opens System Settings
```

Files involved:
- `TranslationAvailabilityClient.swift` — checks `LanguageAvailability.status`
- `TranslationModelGuidance.swift` — computes guidance state
- `GeneralSettingsView.swift` — shows "Open Language & Region" button
- `TranslationErrorMapper` — provides error message strings

### Improved Approach (System Download UI)

```
User copies text → .translationTask fires → session.prepareTranslation()
  → If model not installed → system shows download consent dialog
  → User approves → download happens → translation proceeds
  → No need to go to System Settings at all
```

### Implementation Changes

The change is surprisingly small. In `PopupView.swift`'s `translationAction`, before translating:

```swift
// BEFORE (current): manual preflight + error
let preflightResult = try await availabilityClient.preflight(for: sourceText)
switch preflightResult {
case .ready: break
case .missingModel:
    // Show error, user must go to System Settings
    ...
}
let response = try await session.translate(sourceText)

// AFTER (improved): let the framework handle it
do {
    try await session.prepareTranslation()
} catch {
    // User declined download or source language unknown
    // Fall back to existing error handling
}
let response = try await session.translate(sourceText)
```

**However, there's a catch for Transy's auto-detect use case:** `prepareTranslation()` requires `sourceLanguage` to be non-nil. Transy sets `source: nil` for auto-detection. This means `prepareTranslation()` will throw when source is nil.

**Workaround options:**

1. **Skip `prepareTranslation()`, rely on `translate()` auto-prompting:** When you call `session.translate()` on a `.translationTask()`-provided session, the framework may prompt for downloads automatically if the model isn't installed. The docs for `isReady` state: "If languages aren't installed, attach a `.translationTask()` to a SwiftUI View. Then, call either `prepareTranslation()` or one of the translate functions so the system prompts the person to approve the language downloads." This means **calling `translate()` directly should also trigger the download prompt.**

2. **Detect language first, then prepare:** Use `LanguageAvailability.status(for:to:)` to detect the source language, then create a new configuration with explicit source/target for preparation.

3. **Use `translationPresentation()` as a fallback for download only:** Show the system overlay specifically when a model needs downloading, but use the custom popup for normal translations.

**Recommendation: Option 1** — remove the manual preflight entirely and let `session.translate()` handle download prompts automatically. The `.translationTask()` modifier already provides a session that `canRequestDownloads`. If the model isn't installed, calling `translate()` should trigger the system download prompt.

## What the Download UI Looks Like

The system download UI is a **standard macOS alert/sheet** (not customizable) that:
- States which language model needs to be downloaded
- Shows the approximate download size
- Has "Download" and "Cancel" buttons
- Shows download progress after the user approves
- Is presented by the framework, not by your app

On **iOS**, it appears as a system sheet. On **macOS**, it appears as an alert dialog attached to the relevant window.

**Not customizable:** You cannot change the appearance, text, or behavior of this download prompt. It's a system-provided UI element.

## macOS-Specific Limitations and Considerations

### Known Limitations

1. **macOS 15.0 minimum for `.translationTask()`:** This aligns with Transy's deployment target, so no issue.

2. **`.translationPresentation()` works on macOS 14.4+:** The system overlay version works on older macOS, but Transy doesn't need it (targets 15.0+).

3. **Non-activating panel context:** Transy's popup is a non-activating `NSPanel`. The download prompt from `.translationTask()` may appear as a standalone alert since Transy doesn't have a main window. This needs testing — the alert might not appear if there's no active window to attach to. **Confidence: MEDIUM** — needs runtime verification.

4. **Mac Catalyst 26.0:** The newer `TranslationSession.init(installedSource:target:)` is listed as Mac Catalyst 26.0, suggesting some APIs are still evolving. The `.translationTask()` modifier used by Transy is stable at macOS 15.0.

5. **Model management:** Users can manage downloaded models in System Settings → General → Language & Region → Translation Languages. There's no API to delete models programmatically.

### Testing Downloaded Models

For testing, Apple says: "You can delete locally downloaded models in macOS by choosing System Settings > General > Language & Region > Translation Languages."

## Comparison: Current Approach vs System Download UI

| Aspect | Current (Manual Guidance) | System Download UI |
|--------|--------------------------|-------------------|
| User experience | Error → Settings page → System Settings → find language | Automatic prompt → one-click download |
| Steps for user | 4+ clicks across 2 apps | 1 click |
| Code complexity | `TranslationAvailabilityClient` + `TranslationModelGuidance` + Settings UI | Remove preflight, let framework handle it |
| Customization | Full control over messaging | No control over download prompt appearance |
| Reliability | Relies on user navigating System Settings correctly | System handles everything |
| Offline detection | Manual via `LanguageAvailability.status` | Automatic |
| Source auto-detect | Works (checks with sample text) | `prepareTranslation()` needs explicit source; `translate()` handles auto-detect |

## Implementation Approach

### Minimal Change (Recommended First Step)

Remove the manual preflight check and let `.translationTask()` + `session.translate()` handle download prompts automatically:

```swift
// In PopupView.swift's translationAction:
static func translationAction(...) -> (TranslationSession) async -> Void {
    { session in
        do {
            let response = try await session.translate(requestContext.sourceText)
            await onResult(requestContext.requestID, requestContext.sourceText, response.targetText)
        } catch {
            // Framework may throw if user cancels download or pair is unsupported
            await onError(requestContext.requestID, requestContext.sourceText,
                         TranslationErrorMapper.message(for: error))
        }
    }
}
```

**What gets simplified/removed:**
- `TranslationAvailabilityClient.preflight()` — no longer needed in the popup flow
- `TranslationModelGuidance` — can be simplified or removed
- `settingsStore.recordMissingModel()` — no longer needed
- The entire "Open Language & Region" button in Settings — keep it as a fallback but no longer primary path

**What stays:**
- `TranslationAvailabilityClient` — still useful for Settings page to show which models are installed vs available
- `LanguageAvailability` — useful for feature checks and displaying status

### Settings Page Enhancement

Instead of "go to System Settings", add a "Download Model" button in Settings that triggers `prepareTranslation()` proactively:

```swift
// In GeneralSettingsView
@State private var downloadConfiguration: TranslationSession.Configuration?

Button("Download Model") {
    downloadConfiguration = TranslationSession.Configuration(
        source: detectedSourceLanguage,  // Must be non-nil for prepareTranslation
        target: settingsStore.targetLanguage
    )
}
.translationTask(downloadConfiguration) { session in
    try? await session.prepareTranslation()
}
```

This lets users pre-download models from Transy's Settings page without navigating to System Settings.

## Pros and Cons

### Using System Download UI

| Aspect | Assessment |
|--------|------------|
| ✅ **Dramatically simpler UX** | One-click download vs multi-step System Settings navigation |
| ✅ **Less code** | Remove manual preflight, guidance state machine, Settings button |
| ✅ **Framework handles edge cases** | Download progress, retry, network errors — all handled |
| ✅ **Consistent with Apple ecosystem** | Same download prompt as Translate app, Safari, etc. |
| ❌ **No customization** | Can't style, localize, or modify the download prompt |
| ❌ **Non-activating panel risk** | Download alert may not appear correctly for Transy's floating panel |
| ❌ **Source language requirement** | `prepareTranslation()` needs explicit source; auto-detect complicates proactive downloads |
| ❌ **Black box** | Less visibility into download state for your own UI |

## Recommendation

**Remove the manual preflight from the translation flow and let the framework handle model downloads automatically.**

### Phase 1: Simplify Translation Flow
1. Remove `availabilityClient.preflight()` from `PopupView.translationAction`
2. Let `session.translate()` trigger the download prompt if needed
3. Keep `TranslationErrorMapper` for error handling
4. **Test:** Verify the download prompt appears correctly with Transy's non-activating panel

### Phase 2: Add Proactive Download in Settings
1. Add a "Download Model" button per language pair in Settings
2. Use `.translationTask()` + `session.prepareTranslation()` to trigger download
3. Keep the "Open Language & Region" link as a fallback

### Phase 3: Clean Up
1. Evaluate if `TranslationAvailabilityClient` is still needed
2. Simplify or remove `TranslationModelGuidance`
3. Remove `missingModelContext` from `SettingsStore` if no longer used

### Critical Testing Needed
- **Non-activating panel behavior:** Does the system download alert appear when triggered from Transy's floating `NSPanel`? This needs runtime testing on macOS 15. If the alert doesn't appear, a fallback to the manual approach is needed.
- **Auto-detect + download:** Does `session.translate()` with `source: nil` correctly prompt for downloads after detecting the language? This needs testing.

## References

- **Apple Translation Framework overview:** [developer.apple.com/documentation/translation](https://developer.apple.com/documentation/translation) — HIGH confidence
- **`.translationPresentation()` docs:** Available macOS 14.4+, system overlay approach — [developer.apple.com/documentation/swiftui/view/translationpresentation](https://developer.apple.com/documentation/swiftui/view/translationpresentation(ispresented:text:attachmentanchor:arrowedge:replacementaction:)) — HIGH confidence
- **`.translationTask()` docs:** Available macOS 15.0+, programmatic approach — [developer.apple.com/documentation/swiftui/view/translationtask(_:action:)](https://developer.apple.com/documentation/swiftui/view/translationtask(_:action:)) — HIGH confidence
- **`TranslationSession.prepareTranslation()` docs:** Triggers download prompt proactively — [developer.apple.com/documentation/translation/translationsession/preparetranslation()](https://developer.apple.com/documentation/translation/translationsession/preparetranslation()) — HIGH confidence
- **`TranslationSession.isReady` docs:** "call prepareTranslation() or one of the translate functions so the system prompts the person to approve the language downloads" — HIGH confidence
- **Apple sample code article:** "Translating text within your app" — [developer.apple.com/documentation/translation/translating-text-within-your-app](https://developer.apple.com/documentation/translation/translating-text-within-your-app) — HIGH confidence

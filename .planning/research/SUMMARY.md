# Project Research Summary

**Project:** Transy
**Domain:** macOS menu bar utility — selected-text translation (Japanese/English)
**Researched:** 2026-03-14
**Confidence:** HIGH

## Executive Summary

Transy should be built as a **Swift 6 + SwiftUI/AppKit hybrid**. AppKit owns the system-integration surfaces (`NSPanel`, menu bar presence, global event monitoring), while SwiftUI renders the popup and settings views. This is the right architectural fit for a lightweight macOS utility that must feel native and avoid stealing focus.

After backend comparison, the chosen initial translation backend is **Apple's Translation framework** on **macOS 15+**. That decision optimizes for on-device speed, privacy, and platform-native UX rather than cloud-provider flexibility. The core differentiator remains unchanged: open the popup immediately with the source text as a placeholder/skeleton state, then replace it with the translated result when translation completes.

The highest-risk work is not the translation engine itself. The real Phase 1 risks are validating the chosen system-wide trigger approach, handling privacy permissions clearly, making the popup truly non-activating, and avoiding clipboard corruption or stale reads.

---

## Key Findings

### Recommended Stack

The native Apple stack is the clear choice for v1:

- **Swift 6 / Xcode 16** — primary language and tooling; gives direct access to AppKit, SwiftUI, and the Translation framework
- **SwiftUI** — popup and settings rendering; also the native integration point for the Translation framework APIs
- **AppKit (`NSPanel`, `NSStatusItem`, activation policy control)** — required for the menu bar shell and non-activating popup behavior
- **Apple Translation framework** — on-device translation, automatic source-language detection, system-managed model downloads
- **System-wide trigger monitoring strategy validated in Phase 1** — use the simplest approach that reliably supports double-`Command+C` without compromising UX or distribution goals
- **SPM** — dependency management; no CocoaPods/Carthage required
- **Optional `Defaults` package** — nice-to-have for typed settings, but not mandatory from day one

**Critical version/config requirements:**
- **macOS 15+** minimum deployment target because the Translation framework is the chosen backend
- **`LSUIElement = YES` in `Info.plist`** to keep the app out of the Dock and Cmd+Tab switcher
- **Translation framework is sandbox-compatible**; however, the final trigger-monitoring approach and its permission model must be validated before hard-coding the app's sandbox/capability strategy
- **No API key is required for v1** because translation is on-device

### Expected Features

**Must have for v1 launch:**
- Double-`Command+C` trigger for selected text in another macOS app
- Clear onboarding for whatever privacy permissions the chosen monitoring approach requires
- Non-activating floating popup that does not steal focus from the source app
- Source text shown immediately in a placeholder/skeleton loading state
- On-device Apple translation into the configured target language
- Automatic source-language detection (no manual source picker)
- Target language selection in a dedicated settings window
- Clear model-availability / download guidance when required Apple language models are missing
- Escape + click-outside dismissal
- Menu bar residence with no Dock icon

**Should have after the core loop is validated (v1.x):**
- Launch at Login toggle
- Copy translation action in the popup
- Provider abstraction exposed in settings for future external-provider fallback

**Defer to v2+:**
- Popup positioning near the current selection (AXUIElement-based positioning)
- Custom shortcut remapping UI
- OCR / screenshot translation

### Architecture Approach

The architecture should follow the **AppKit shell + SwiftUI leaf nodes** pattern:

- **App shell:** menu bar item, popup window controller, activation policy, settings window lifecycle
- **Trigger layer:** detects double-`Command+C`, captures the selected text safely, and restores the previous clipboard contents
- **Coordinator layer:** shows the popup immediately in `.loading(sourceText)` state, requests translation, and then transitions the popup to `.result` or `.error`
- **Translation layer:** define a `TranslationService` protocol from day one, with an `AppleTranslationClient` as the initial implementation; this keeps future provider fallback possible without refactoring the coordinator/UI boundary
- **Settings layer:** stores the target language and presents model-availability guidance; no API key handling is needed in v1

### Critical Pitfalls

1. **Popup stealing focus** — the popup must be an `NSPanel` configured to avoid activating the app; a normal `NSWindow` / `WindowGroup` is the wrong primitive here.
2. **Clipboard race on capture** — the source app may not have written the copied text yet when the trigger fires; Phase 2 must validate a small delayed read strategy before capture is considered correct.
3. **Clipboard trust erosion** — previous clipboard contents must be restored after capture so the app does not silently destroy the user's clipboard.
4. **Permission ambiguity** — the trigger-monitoring API choice determines whether only Accessibility or additional privacy permissions are needed; this must be validated early and documented clearly in the implementation plan.
5. **Model availability** — Apple Translation may require system model downloads for a language pair; the app must surface this as guidance, not as a silent failure.
6. **macOS floor mismatch** — Translation framework usage hard-locks the project to macOS 15+.

---

## Implications for Roadmap

The current 4-phase roadmap is directionally correct once the research summary is reconciled with the Apple Translation decision:

- **Phase 1 — App Shell:** set the macOS 15 target, configure `LSUIElement`, create the menu bar shell, and validate the trigger-monitoring + sandbox/capability strategy
- **Phase 2 — Trigger & Popup:** implement the double-`Command+C` trigger, permission guidance, delayed clipboard capture, clipboard restoration, and non-activating popup
- **Phase 3 — Translation Loop:** integrate Apple Translation, automatic source-language detection, and stale-request/error handling
- **Phase 4 — Settings:** add target language settings and model download guidance

The main cleanup required after research is not a new roadmap shape — it is **document consistency**. Older cloud-backend assumptions should not drive Phase 1 decisions anymore.

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | SwiftUI/AppKit + Apple Translation is directly supported by Apple on macOS 15+ |
| Core UX | HIGH | Non-activating popup + immediate placeholder remains the right interaction model |
| Roadmap shape | HIGH | 4 phases still match the chosen backend and current requirements |
| Trigger permissions | MEDIUM | Needs real-device validation because permission behavior depends on the final monitoring API |
| Popup positioning | MEDIUM | Fixed position is acceptable for v1, but should be validated in practice |

**Overall confidence: HIGH**

### Gaps to Address

- Validate the exact monitoring API and the privacy-permission combination it requires before Phase 1 implementation locks in app capabilities.
- Confirm the delayed clipboard-read strategy with real-device testing.
- Decide whether `Defaults` is worth adding in Phase 1 or whether plain `UserDefaults` is sufficient until settings become more complex.

---

## Sources

### Primary
- Apple Developer Documentation: Translation framework — https://developer.apple.com/documentation/translation
- Apple Developer Documentation: Translating text within your app — https://developer.apple.com/documentation/translation/translating-text-within-your-app
- Apple Developer Documentation: `LanguageAvailability.supportedLanguages` — https://developer.apple.com/documentation/translation/languageavailability/supportedlanguages
- Apple Developer Documentation: `NSPanel`, `NSStatusItem`, `NSEvent.addGlobalMonitorForEvents`, activation policy APIs

### Secondary
- WWDC24: Meet the Translation API — https://developer.apple.com/videos/play/wwdc2024/10117/
- Competitor/product references: DeepL, Bob, PopClip — useful for UX comparison, not as the chosen backend

---
*Research completed: 2026-03-14*
*Reconciled after backend selection: Apple Translation framework*
*Ready for roadmap: yes*

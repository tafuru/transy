# Stack Research

**Domain:** macOS menu bar utility — selected-text translation
**Researched:** 2026-03-14
**Confidence:** HIGH

---

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Swift | 6.0 (Xcode 16) | Primary language | Direct access to AppKit, SwiftUI, and Apple's Translation framework. Strong concurrency support for trigger → popup → translate flow. |
| SwiftUI | macOS 15+ target | Popup and settings UI | Natural fit for placeholder states, settings forms, and Translation framework integration. |
| AppKit (`NSPanel`, `NSStatusItem`, activation policy APIs) | macOS 15+ target | Menu bar shell and non-activating popup | Required for the utility-style UX. SwiftUI alone is not enough for this class of macOS app. |
| Translation framework | macOS 15+ | On-device translation | Chosen v1 backend for speed, privacy, and native integration. Supports automatic source-language detection and model availability APIs. |
| Swift Package Manager | Xcode built-in | Dependency management | Native Xcode integration, low friction, no need for CocoaPods/Carthage. |
| `UserDefaults` or `Defaults` | Optional | Settings persistence | Plain `UserDefaults` is enough initially; `Defaults` is a good upgrade once settings grow more complex. |

### Configuration Notes

- **Minimum deployment target:** `macOS 15+` because the Translation framework is the chosen backend.
- **Dockless behavior:** set **`LSUIElement = YES` in `Info.plist`**, not in entitlements.
- **Sandboxing:** Apple's Translation framework itself is sandbox-compatible. The final sandbox/capability configuration should be chosen only after Phase 1 validates the system-wide trigger-monitoring approach.
- **Real-device testing is mandatory:** menu bar behavior, clipboard timing, and privacy-permission flows are not trustworthy in Simulator alone.
- **No API key is required in v1:** translation is on-device.

---

## Installation / Project Bootstrap

This is a native Swift/Xcode project.

```text
1. Create a new macOS app project in Xcode 16
2. Set the deployment target to macOS 15.0
3. Add LSUIElement = YES to Info.plist
4. Create a menu bar shell and non-activating popup foundation
5. Validate the system-wide trigger-monitoring strategy on a real Mac before freezing entitlements/capabilities
6. Add optional SPM dependencies only when they clearly reduce code or risk
```

---

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| Swift + SwiftUI/AppKit | Tauri | Only if cross-platform becomes more important than the best native macOS UX. Even then, native bridges would still be required for core macOS-only behavior. |
| Swift + SwiftUI/AppKit | Electron | Not a good fit. The project exists partly to avoid a heavy, non-native feel. |
| Apple Translation framework | DeepL API | Consider as a future fallback/provider option if on-device quality or language availability proves insufficient. |
| Apple Translation framework | Google Cloud Translation / OpenAI | Consider later only if cloud translation is needed for language coverage or specialized quality tradeoffs. |
| Plain `UserDefaults` | `Defaults` package | Use `Defaults` when the settings layer becomes more complex or needs better typing/observation ergonomics. |

---

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Electron | Heavy runtime, weaker native feel, wrong fit for this utility | Swift + SwiftUI/AppKit |
| Catalyst | Awkward for menu bar and popup-heavy utility behavior | Native AppKit + SwiftUI |
| Cloud-first translation backend for v1 | Adds network latency and key management to the core loop | Apple Translation framework |
| Treating `LSUIElement` as an entitlement | It's an Info.plist key, not a capability | `Info.plist` configuration |
| Locking in CGEventTap before validation | It may introduce stricter permission/distribution constraints than necessary | Validate the simplest viable monitoring approach in Phase 1 |

---

## Stack Patterns by Surface

### Translation Popup
- Use `NSPanel` with non-activating behavior
- Host SwiftUI content via `NSHostingView` / `NSHostingController`
- Keep the popup stateful: `.loading(sourceText)` → `.result(translatedText)` or `.error(message)`

### Trigger Monitoring
- Start with an abstraction, not a hard-coded API assumption
- Validate the chosen system-wide monitoring approach on a real machine
- Keep permission onboarding and monitoring logic separate from popup/translation code

### Settings
- Dedicated settings window or Settings scene for target language
- Model availability / download guidance belongs in settings and in translation error handling
- `UserDefaults` is sufficient initially; upgrade to `Defaults` only if it meaningfully improves implementation clarity

---

## Version Compatibility

| Capability | Compatible macOS | Notes |
|------------|------------------|-------|
| Swift 6 / Xcode 16 | macOS 15+ target | Matches the chosen Translation framework floor |
| Translation framework | macOS 15+ | Hard requirement for the chosen v1 backend |
| `NSPanel`, `NSStatusItem` | Broadly supported | Stable AppKit primitives; no special risk |
| `MenuBarExtra` | macOS 13+ | Available, but the effective app target is still macOS 15+ |
| SwiftUI placeholder styling | Broadly supported | Suitable for the loading-state UX |

---

## Sources

- Apple Developer Documentation: Translation framework
- Apple Developer Documentation: Translating text within your app
- Apple Developer Documentation: `LanguageAvailability.supportedLanguages`
- Apple Developer Documentation: `NSPanel`, `NSStatusItem`, activation policy APIs
- WWDC24: Meet the Translation API

---
*Stack research for: macOS menu bar selected-text translation utility (Transy)*
*Researched: 2026-03-14*

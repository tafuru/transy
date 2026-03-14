# Architecture Research

**Domain:** macOS menu bar utility — selected-text translation
**Researched:** 2026-03-14
**Confidence:** HIGH

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

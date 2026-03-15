# Phase 4: Settings - Research

**Researched:** 2026-03-15
**Domain:** macOS 15+ menu bar settings, persisted translation target language, Apple Translation model guidance
**Confidence:** MEDIUM

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
#### Settings Window Information Density
- Keep Phase 4 settings as a single compact pane rather than a sidebar or multi-page preferences UI.
- Keep the surface controls-first with only minimal supporting copy.
- Show model guidance in the same pane only when it is relevant, rather than reserving permanent space for it.
- Let the window stay compact by default and grow slightly only when guidance becomes visible.

#### Target Language Picker Presentation
- Show a broad set of supported target-language choices rather than a tiny curated shortlist.
- Use a standard native picker / menu presentation instead of a custom searchable or recents-driven UI.
- Display natural language names only; do not include language codes or dual-name formatting.
- Initialize the Phase 4 default from the OS preferred language rather than preserving the temporary fixed-English default from Phase 3.

#### Model Guidance Behavior
- Missing-model messaging in Settings should stay short and matter-of-fact, but it should still make the next action obvious.
- Provide one clear action that guides the user to the relevant System Settings path for Apple Translation models.
- When the app can confidently determine that the required model for a known source/target pair is missing, show that guidance immediately in Settings.
- When the pair is not yet known (for example, initial settings before any translation context exists), show only generic guidance in Settings; after a real translation reveals `Translation model not installed.`, Settings can later surface pair-specific guidance.

#### Settings Change Propagation
- Persist target-language changes automatically; no explicit Save / Apply button is needed.
- A new selection should affect the next translation request immediately.
- An in-flight or already visible popup should not mutate mid-request; it keeps the language/configuration it started with.
- Once Transy has stored a chosen target language, later OS preferred-language changes should not auto-overwrite that stored choice.

### Claude's Discretion
- Exact section headers, spacing, and row ordering inside the single-pane settings window.
- Exact wording of the generic and pair-specific guidance copy, as long as it stays short, quiet, and action-oriented.
- Exact compact/expanded window dimensions as long as the default view stays small and the guidance state only grows modestly.
- Exact mechanism for remembering enough recent translation context to surface pair-specific guidance later, as long as generic guidance is used whenever pair certainty is unavailable.

### Deferred Ideas (OUT OF SCOPE)
- Searchable language selection, recent languages, or favorites remain out of scope for Phase 4.
- Any provider selection, unsupported-pair fallback, or external translation-provider work stays in later phases.
- Mid-flight mutation of a currently visible popup after a settings change is intentionally deferred; Phase 4 only requires the next request to use the new configuration.
- Any attempt to download or manage Apple translation assets directly in-app remains out of scope; guidance should point to Apple’s System Settings flow.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| APP-02 | User can choose the target translation language in a settings window. | Use a dedicated `SettingsStore` with `UserDefaults` persistence, populate the picker from `LanguageAvailability.supportedLanguages`, and inject the store into the existing SwiftUI `Settings` scene. Snapshot the chosen language at trigger time so the next translation uses it without mutating an active popup. |
| APP-03 | User is guided to download any Apple translation models required for the selected language pair when they are not yet available on the device. | Keep popup copy terse, but evaluate settings guidance separately: generic guidance when no reliable source language is known; pair-specific guidance only when source language is known with confidence and `LanguageAvailability.status(from:to:)` reports `.supported`. Prefer safe copy-guided System Settings navigation over unverified deep-link dependence. |
</phase_requirements>

## Summary

The safest Phase 4 integration is to add a single persisted `SettingsStore` and make it the only target-language source of truth for future requests, while keeping each already-started popup request on its own frozen language snapshot. The current codebase already gives a clean seam for that: `AppDelegate` owns runtime translation flow, `TransyApp` already owns the native `Settings` scene, and `PopupView` already accepts an injected `TranslationAvailabilityClient`. That means Phase 4 does **not** need a popup redesign or a reactive live binding from Settings into an already-visible popup. Read the current target language at trigger time, build the request’s `TranslationAvailabilityClient` from that snapshot, and let the next trigger see the new persisted value.

For the language list, use Apple’s own `LanguageAvailability.supportedLanguages` rather than a manually curated enum/list. A live probe on this machine returned 21 supported target languages, including region/script-distinct entries such as `en` vs `en-GB` and `zh` vs `zh-TW`. The important UI detail is that “natural language names only” should be derived from `Locale.current.localizedString(forIdentifier: language.minimalIdentifier)`, not just the bare language code, otherwise distinct supported targets collapse into duplicate labels like “English” / “English” and “Chinese” / “Chinese”.

For missing-model guidance, the popup path from Phase 3 should remain unchanged: preflight with `LanguageAvailability.status(for:to:)`, then show terse inline errors only. Settings guidance should be a **separate** concern. The macOS 15-floor API surface does not provide a clean in-app download-management path; newer local SDK interfaces show `TranslationSession.canRequestDownloads`, `TranslationError.notInstalled`, and direct installed-source initializers only on macOS 26, so they are out of bounds for this app. I could verify that macOS System Settings has a Language & Region pane (`com.apple.Localization-Settings.extension`) and a `translation` anchor, but I could not verify a production-safe deep link to that anchor via `x-apple.systempreferences:` without UI validation, and AppleScript-style pane control would be too heavy/risky for a quiet utility app. Safe baseline: short copy, one clear action, and no dependency on fragile automation.

**Primary recommendation:** Build Phase 4 around a `UserDefaults`-backed `SettingsStore` that persists `Locale.Language.minimalIdentifier`, snapshots target language per popup request, drives the picker from `LanguageAvailability.supportedLanguages`, and keeps settings guidance generic unless a source/target pair is known with confidence.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `UserDefaults` | Foundation / macOS 15+ | Persist selected target language across launches | Smallest reliable persistence layer for one setting; no package needed |
| `Locale.Language` | Foundation / macOS 15+ | Canonical in-app representation of translation target language | Matches Apple Translation APIs directly; avoids custom code/enum drift |
| `LanguageAvailability` | Translation / macOS 15+ | Load supported target languages and evaluate installed/supported/unsupported state | Official framework surface for both picker population and model guidance |
| `Settings { ... }` scene | SwiftUI / macOS 11+ | Native single-instance settings window | Already wired in `TransyApp`; fits Cmd+, and native Settings behavior |
| `OpenSettingsAction` | SwiftUI / macOS 14+ | Open the native Settings scene from the menu bar | Already used successfully via `@Environment(\\.openSettings)` |
| `@Observable` + `@MainActor` | Observation / Swift 6 | Drive store and settings UI updates without Combine boilerplate | Matches current `AppState` / `TranslationCoordinator` style |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `NSWorkspace.shared.open(_:)` | AppKit / macOS 15+ | Open System Settings app or a verified settings URL | Use for the single guidance action; keep the URL path conservative |
| `LanguageAvailability.status(from:to:)` | Translation / macOS 15+ | Evaluate a known source/target pair without sample text | Use only when a source language is already known with confidence |
| `Swift Testing` | Xcode 16+ | Unit-test persistence, default resolution, and guidance-state logic | Use for all non-UI Phase 4 behavior |
| `XCTest` UI target | Xcode 16+ | Placeholder only | Keep available, but expect Phase 4 LSUIElement/window validation to stay manual |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `UserDefaults` string persistence | `@AppStorage` directly in the view | `@AppStorage` is fine for leaf views, but a dedicated store is safer because the translation pipeline also needs the setting outside SwiftUI view code |
| `Locale.Language` persisted as identifier string | Custom hard-coded `TargetLanguage` enum | A manual enum drifts from Apple’s supported language set and duplicates framework data |
| Dynamic picker from `supportedLanguages` | Static curated list | Static list is easier short-term but violates the “broad supported list” decision and risks missing supported variants |
| Request-time target snapshot | Live-observed store inside `PopupView` | Live observation can mutate active requests/popups, violating locked behavior |
| Copy-guided System Settings action | AppleScript automation or guessed deep-link-only behavior | Apple Events risk new prompts; guessed URLs are fragile until manually verified |

**Installation:**
```swift
import AppKit
import Foundation
import Observation
import SwiftUI
import Translation
```

## Architecture Patterns

### Recommended Project Structure
```text
Transy/
├── AppDelegate.swift                         # owns runtime trigger/popup flow and settings store
├── TransyApp.swift                           # passes store into existing Settings scene
├── Settings/
│   ├── SettingsStore.swift                   # persisted target language + default resolution
│   ├── SettingsView.swift                    # compact picker + conditional guidance
│   ├── SupportedLanguageOption.swift         # localized display helper over Locale.Language
│   └── TranslationModelGuidance.swift        # generic vs pair-specific settings guidance logic
├── Translation/
│   ├── TranslationAvailabilityClient.swift   # popup preflight remains terse
│   └── TranslationCoordinator.swift          # unchanged popup state machine
└── Popup/
    ├── PopupController.swift                 # inject request-scoped availability client
    └── PopupView.swift                       # consumes frozen request target language
```

### Pattern 1: AppDelegate-Owned SettingsStore with Scene Injection
**What:** Create one `SettingsStore` instance in `AppDelegate`, then hand the same instance to the `Settings` scene from `TransyApp`.

**When to use:** Always. This avoids split state between the menu/settings side and the translation-runtime side.

**Example:**
```swift
// Source: project architecture (`TransyApp` already sees `appDelegate`) + existing @Observable pattern
@MainActor
@Observable
final class SettingsStore {
    private enum Key {
        static let targetLanguage = "settings.targetLanguage"
    }

    private let defaults: UserDefaults
    private(set) var targetLanguage: Locale.Language

    init(
        defaults: UserDefaults = .standard,
        initialLanguage: Locale.Language
    ) {
        self.defaults = defaults
        if let stored = defaults.string(forKey: Key.targetLanguage) {
            self.targetLanguage = Locale.Language(identifier: stored)
        } else {
            self.targetLanguage = initialLanguage
            defaults.set(initialLanguage.minimalIdentifier, forKey: Key.targetLanguage)
        }
    }

    func updateTargetLanguage(_ language: Locale.Language) {
        targetLanguage = language
        defaults.set(language.minimalIdentifier, forKey: Key.targetLanguage)
    }
}

@main
struct TransyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("Transy", systemImage: "character.bubble") {
            MenuBarView()
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView(settingsStore: appDelegate.settingsStore)
        }
    }
}
```

### Pattern 2: Snapshot Target Language Per Request
**What:** Read the persisted target language when a trigger starts, then pass that frozen value into the popup request.

**When to use:** Always. This satisfies “next request uses new target” without mutating an active popup/request.

**Example:**
```swift
// Source: project code (`PopupView` already accepts an injected TranslationAvailabilityClient)
private func handleTrigger(preSnapshot: [NSPasteboardItem]) {
    // ...
    let requestTarget = settingsStore.targetLanguage
    let availabilityClient = TranslationAvailabilityClient(targetLanguage: requestTarget)

    _ = translationCoordinator.begin(sourceText: normalizedText)
    popupController.show(
        translationCoordinator: translationCoordinator,
        availabilityClient: availabilityClient
    ) { [weak self] in
        self?.translationCoordinator.dismiss()
    }
}
```

### Pattern 3: Use Apple’s Supported-Language Set for the Picker
**What:** Load the picker options from `LanguageAvailability.supportedLanguages`, then render natural-language labels from the locale identifier rather than the bare language code.

**When to use:** For the broad native picker/menu locked by the context.

**Example:**
```swift
// Source: local Translation SDK interface + live probe on this machine
struct SupportedLanguageOption: Identifiable, Hashable {
    let language: Locale.Language
    let label: String

    var id: String { language.minimalIdentifier }

    static func load(locale: Locale = .current) async -> [SupportedLanguageOption] {
        let languages = await LanguageAvailability().supportedLanguages
        return languages
            .map { language in
                SupportedLanguageOption(
                    language: language,
                    label: locale.localizedString(forIdentifier: language.minimalIdentifier)
                        ?? language.minimalIdentifier
                )
            }
            .sorted { $0.label.localizedCaseInsensitiveCompare($1.label) == .orderedAscending }
    }
}
```

### Pattern 4: Separate Popup Preflight from Settings Guidance
**What:** Keep `TranslationAvailabilityClient.preflight(for:)` as the popup’s terse gate, but evaluate settings guidance independently so Settings can be generic when the source is unknown and pair-specific only when it is known.

**When to use:** Whenever Phase 4 guidance must complement, not replace, Phase 3 popup behavior.

**Example:**
```swift
// Source: local Translation SDK interface (`status(from:to:)` exists for known pairs)
enum TranslationModelGuidance: Equatable {
    case none
    case generic(target: Locale.Language)
    case pairSpecific(source: Locale.Language, target: Locale.Language)
}

func guidance(
    knownSource: Locale.Language?,
    target: Locale.Language,
    availability: LanguageAvailability
) async -> TranslationModelGuidance {
    guard let knownSource else { return .generic(target: target) }

    let status = await availability.status(from: knownSource, to: target)
    switch status {
    case .supported:
        return .pairSpecific(source: knownSource, target: target)
    default:
        return .none
    }
}
```

### Anti-Patterns to Avoid
- **Observing live settings inside the popup:** This can change `TranslationSession.Configuration.target` during an active request and violates the locked “active popup/request does not mutate” rule.
- **Hard-coding a separate language catalog:** Apple already exposes supported targets; a manual enum/list will drift and forces unnecessary maintenance.
- **Letting Settings own popup logic:** Settings should present preferences and guidance, not become the runtime translation coordinator.
- **Using AppleScript/System Events automation as the primary guidance action:** It is too heavy for a quiet menu bar utility and may introduce unwanted automation prompts.
- **Trying to build in-app model download UI on macOS 15:** The current deployment floor does not offer a clean, supported path for that.

## Don’t Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Supported target-language catalog | Custom static enum/list copied from blog posts or old docs | `await LanguageAvailability().supportedLanguages` | Current framework data already includes supported variants and avoids stale lists |
| Persisted language format | Custom structs serialized ad hoc | `Locale.Language.minimalIdentifier` in `UserDefaults` | Stable, small, and reconstructs `Locale.Language` directly |
| Settings-window lifecycle | Custom NSWindow singleton/controller | Existing `Settings` scene + `openSettings` | Native single-instance behavior already matches the app’s architecture |
| Active-request language switching | Mutating `PopupView` off live store changes | Snapshot target language at trigger time | Prevents mid-flight state mutation and Phase 3 regressions |
| Translation-model install handling | In-app downloader / custom asset manager | Settings guidance + System Settings action | macOS 15 Translation APIs do not expose a safe direct download-management flow |
| Deep-link certainty | Shipping an unverified translation-pane URL as the only path | Copy-guided System Settings action, with optional manual URL validation | Unverified links create dead-end UX if the scheme changes or anchor is wrong |

**Key insight:** The tricky parts of this phase are not the picker UI; they are source-of-truth discipline and framework-boundary discipline. Use Apple’s language catalog, Apple’s settings scene, and frozen request snapshots. Avoid inventing your own catalog, window lifecycle, or model-management workflow.

## Common Pitfalls

### Pitfall 1: Two Sources of Truth for the Target Language
**What goes wrong:** Settings writes one value, while popup translation still uses a separate default or cached English fallback.
**Why it happens:** The current app has no shared settings object yet, so it is easy to update only the UI side.
**How to avoid:** Create one `SettingsStore`, inject it into Settings, and read from it at trigger time for popup requests.
**Warning signs:** Picker shows one language, but the next translation still behaves like English.

### Pitfall 2: Duplicate or Ambiguous Picker Labels
**What goes wrong:** Distinct supported targets display as duplicate natural-language names.
**Why it happens:** `localizedString(forLanguageCode:)` collapses variants like `en`/`en-GB` and `zh`/`zh-TW`.
**How to avoid:** Build labels from `localizedString(forIdentifier: language.minimalIdentifier)`.
**Warning signs:** Picker contains repeated “English” or repeated “Chinese” rows.

### Pitfall 3: Assuming “Model Not Installed” Means the Source Language Is Known
**What goes wrong:** Settings presents pair-specific guidance for a guessed source language.
**Why it happens:** `LanguageAvailability.status(for:text,to:)` returns only a status, not the detected source language.
**How to avoid:** Show generic guidance unless a source language was learned from a trustworthy signal and persisted separately.
**Warning signs:** Settings claims a specific source/target pair even though the app never actually stored the source language.

### Pitfall 4: Regressing Phase 3 by Making the Popup Reactive to Settings
**What goes wrong:** An in-flight popup changes language or session configuration after the user opens Settings.
**Why it happens:** Live observation feels convenient, but the popup is already request-scoped.
**How to avoid:** Freeze the request’s target language before creating `TranslationAvailabilityClient` / `TranslationSession.Configuration`.
**Warning signs:** Changing the picker while a popup is visible changes the active popup’s behavior or text.

### Pitfall 5: Breaking LSUIElement Quietness While Opening Settings
**What goes wrong:** Opening settings causes Dock/app-switcher behavior to regress or spawns multiple settings windows.
**Why it happens:** Developers add custom window management or activation-policy changes while trying to “help” the Settings scene.
**How to avoid:** Keep the existing `NSApp.activate()` + `openSettings()` pattern; do not change activation policy for Phase 4.
**Warning signs:** Dock icon appears, app enters regular activation behavior, or repeated menu clicks stack settings windows.

### Pitfall 6: Depending on an Unverified Translation-Settings Deep Link
**What goes wrong:** The “Open System Settings” button opens the wrong place or a dead link.
**Why it happens:** Translation-specific `x-apple.systempreferences:` behavior is not documented in the repo and was not fully verifiable from local artifacts alone.
**How to avoid:** Make the copy self-sufficient (“General → Language & Region → Translation Languages”) and treat any deeper link as an optional manual-validated improvement.
**Warning signs:** Button opens generic Settings with no user clue what to do next, or opens a wrong pane.

## Code Examples

Verified patterns from local SDK interfaces and current project architecture:

### Persist a `Locale.Language` via `minimalIdentifier`
```swift
// Source: local Foundation runtime probe + project SettingsStore recommendation
let storedIdentifier = userDefaults.string(forKey: "settings.targetLanguage") ?? "en"
let targetLanguage = Locale.Language(identifier: storedIdentifier)
userDefaults.set(targetLanguage.minimalIdentifier, forKey: "settings.targetLanguage")
```

### Freeze target language for the popup request
```swift
// Source: project code (`PopupView` injects TranslationAvailabilityClient)
let requestTarget = settingsStore.targetLanguage
let availabilityClient = TranslationAvailabilityClient(targetLanguage: requestTarget)
popupController.show(
    translationCoordinator: translationCoordinator,
    availabilityClient: availabilityClient,
    onDismiss: onDismiss
)
```

### Build broad, distinct, natural-language picker rows
```swift
// Source: local Translation SDK probe on macOS 15+
let options = await LanguageAvailability().supportedLanguages
let rows = options.map { language in
    (
        id: language.minimalIdentifier,
        title: Locale.current.localizedString(forIdentifier: language.minimalIdentifier)
            ?? language.minimalIdentifier
    )
}
```

### Known-pair guidance check
```swift
// Source: local Translation.swiftinterface (`status(from:to:)`)
let availability = LanguageAvailability()
let status = await availability.status(from: sourceLanguage, to: targetLanguage)
if status == .supported {
    // show short pair-specific guidance in Settings
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Fixed English target (`Locale.Language(identifier: "en")`) | Persisted user-selected target language | Phase 4 | Translation target becomes configurable without altering Phase 3 popup design |
| Static/manual target-language lists | `LanguageAvailability.supportedLanguages` | Translation framework on macOS 15+ | Picker can stay broad and framework-aligned |
| Blind `translate(_:)` and hope for framework handling | Preflight with `LanguageAvailability` and keep model guidance in Settings | Phase 3 → Phase 4 | Prevents surprise framework UI in the popup path |
| Considering direct download/session control APIs | Ignore macOS 26-only conveniences on a macOS 15 app floor | Current local SDK | `TranslationSession.canRequestDownloads`, `TranslationError.notInstalled`, direct installed-source init, and `cancel()` are not safe plan assumptions |
| Potential automation/deep-link tricks for pane control | Copy-guided Settings action first, deeper link only after manual validation | Phase 4 research | Keeps guidance reliable even if a translation-pane deep link is unavailable or fragile |

**Deprecated/outdated:**
- **Hard-coded generic-English target:** Valid only as a Phase 3 bridge; replace as soon as the store exists.
- **View-only persistence (`@AppStorage` as the whole solution):** Too narrow once non-view runtime code also needs the setting.
- **AppleScript pane control as a primary UX path:** Technically possible to inspect panes/anchors locally, but not appropriate as the baseline shipping behavior for this app.

## Open Questions

1. **Can `x-apple.systempreferences:` target the Translation Languages anchor directly on macOS 15+?**
   - What we know: Local System Settings inspection confirms the Language & Region pane ID is `com.apple.Localization-Settings.extension` and it exposes anchors `Language`, `Region`, and `translation`. Opening `x-apple.systempreferences:com.apple.Localization-Settings.extension` does route to the Language & Region pane on this machine.
   - What's unclear: Whether a URL form such as `x-apple.systempreferences:com.apple.Localization-Settings.extension?translation` reliably lands on the `translation` anchor across supported macOS 15 builds.
   - Recommendation: Treat anchor-level deep-linking as a manual validation spike, not a plan dependency. Baseline copy must still work if the button only opens System Settings or the Language & Region pane.

2. **How should pair-specific guidance be learned after a missing-model popup if the source language was auto-detected but not surfaced?**
   - What we know: `LanguageAvailability.status(for:text,to:)` returns only status, not the detected source language.
   - What's unclear: Whether the phase should introduce an additional reliable source-language capture path or remain generic until a future request reveals source language through a different trusted signal.
   - Recommendation: Plan generic guidance as the required baseline. Treat pair-specific guidance as conditional on reliable stored source context, not as a must-have for every missing-model case.

3. **Will the compact/expanded settings window size adjust cleanly with only SwiftUI sizing?**
   - What we know: The current Settings view is a fixed-frame placeholder, and the locked UX wants modest growth only when guidance appears.
   - What's unclear: Whether a simple conditional `.frame(height:)` is sufficient in the real Settings scene across macOS 15 builds or whether a small AppKit window-size nudge is needed.
   - Recommendation: Keep the first implementation simple and add a manual UI check to verify compact and expanded states before considering any AppKit window accessor.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Swift Testing (unit) in `TransyTests`; XCTest UI target present but mostly unused |
| Config file | none — Xcode project target configuration in `project.yml` / `Transy.xcodeproj` |
| Quick run command | `xcodebuild test -scheme Transy -destination 'platform=macOS' -only-testing:TransyTests` |
| Full suite command | `xcodebuild test -scheme Transy -destination 'platform=macOS'` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| APP-02 | First launch resolves a default target from OS preferences, then persists and reuses stored value on later launches | unit | `xcodebuild test -scheme Transy -destination 'platform=macOS' -only-testing:TransyTests/SettingsStoreTests` | ❌ Wave 0 |
| APP-02 | Changing the picker updates the next translation request but does not mutate an already-active popup request | unit | `xcodebuild test -scheme Transy -destination 'platform=macOS' -only-testing:TransyTests/TargetLanguageSnapshotTests` | ❌ Wave 0 |
| APP-02 | Settings window remains native/single-instance and does not regress LSUIElement behavior | manual smoke | `manual` | ✅ existing infrastructure, but no automated check |
| APP-03 | Generic guidance appears when the target is selected but no reliable source/target pair is known | unit | `xcodebuild test -scheme Transy -destination 'platform=macOS' -only-testing:TransyTests/TranslationModelGuidanceTests` | ❌ Wave 0 |
| APP-03 | Pair-specific guidance appears only when a reliable known pair is missing its model | unit | `xcodebuild test -scheme Transy -destination 'platform=macOS' -only-testing:TransyTests/TranslationModelGuidanceTests` | ❌ Wave 0 |
| APP-03 | The System Settings action and copy lead a human to the correct Translation Languages path | manual smoke | `manual` | ✅ existing infrastructure, but no automated check |

### Sampling Rate
- **Per task commit:** `xcodebuild test -scheme Transy -destination 'platform=macOS' -only-testing:TransyTests`
- **Per wave merge:** `xcodebuild test -scheme Transy -destination 'platform=macOS'`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `TransyTests/SettingsStoreTests.swift` — persistence, first-run default resolution, stored-value precedence
- [ ] `TransyTests/TargetLanguageSnapshotTests.swift` — prove active popup/request keeps its original target while next request sees updated settings
- [ ] `TransyTests/TranslationModelGuidanceTests.swift` — generic vs pair-specific guidance reducer/evaluator
- [ ] Manual checklist step: open Settings repeatedly from the menu bar and confirm native single-instance behavior with no Dock icon regression
- [ ] Manual checklist step: validate the chosen “Open System Settings” action on macOS 15 with a missing-model scenario

## Plan Boundary Recommendations

### 04-01 — SettingsStore
Scope this plan to the non-UI contract:
- Add `SettingsStore` with `UserDefaults` persistence of `Locale.Language.minimalIdentifier`
- Implement first-run default resolution from OS preferred language, with stored-value precedence forever after
- Inject the single store instance from `AppDelegate` into `TransyApp` / `SettingsView`
- Snapshot the target language at trigger time and pass it into the popup request path
- Update/add tests for persistence and request snapshot behavior

**Do not include in 04-01:** picker layout, supported-language loading UI, guidance copy, window sizing, System Settings actions.

### 04-02 — SettingsWindow
Scope this plan to the user-facing settings behavior:
- Replace the placeholder `SettingsView` with the compact native pane
- Load and sort supported target languages for the picker
- Render distinct natural-language labels only
- Add conditional model guidance UI and the single System Settings action
- Keep Settings single-instance by leaning on the existing `Settings` scene; validate rather than inventing a custom guard unless testing proves a bug
- Add unit tests for guidance-state logic plus manual smoke checks for window behavior, guidance visibility, and Dock/activation safety

**Do not include in 04-02:** reworking the popup UI, provider switching, custom searchable picker work, or any in-app asset download flow.

## Sources

### Primary (HIGH confidence)
- Local Xcode SDK interface: `/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/System/Library/Frameworks/Translation.framework/Versions/A/Modules/Translation.swiftmodule/arm64e-apple-macos.swiftinterface` — checked `LanguageAvailability.supportedLanguages`, `status(for:to:)`, `status(from:to:)`, `TranslationSession.Configuration`, and macOS 26-only APIs (`canRequestDownloads`, `cancel()`, `TranslationError.notInstalled`)
- Local Xcode SDK interface: `/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/System/Library/Frameworks/SwiftUI.framework/Versions/A/Modules/SwiftUI.swiftmodule/arm64e-apple-macos.swiftinterface` — checked `Settings` scene and `OpenSettingsAction`
- Local System Settings AppleScript dictionary: `/System/Applications/System Settings.app/Contents/Resources/SystemPreferences.sdef` — checked pane/anchor support
- Live AppleScript probe of System Settings panes/anchors on this machine — confirmed `com.apple.Localization-Settings.extension` and anchors `Language`, `Region`, `translation`
- Project code: `Transy/AppDelegate.swift`, `Transy/TransyApp.swift`, `Transy/MenuBar/MenuBarView.swift`, `Transy/Popup/PopupView.swift`, `Transy/Translation/TranslationAvailabilityClient.swift`, `Transy/AppState.swift`
- Local runtime probes executed during research:
  - `LanguageAvailability().supportedLanguages` returned 21 target languages on this machine
  - `Locale.Language` round-trips cleanly through JSON encoding and `minimalIdentifier`
  - `xcodebuild test -scheme Transy -destination 'platform=macOS'` passed (`** TEST SUCCEEDED **`)

### Secondary (MEDIUM confidence)
- Existing project verification/state documents: `.planning/STATE.md`, `.planning/ROADMAP.md`, `.planning/phases/03-translation-loop/03-RESEARCH.md`, `.planning/phases/01-app-shell/01-RESEARCH.md`

### Tertiary (LOW confidence)
- Candidate deep-link form `x-apple.systempreferences:com.apple.Localization-Settings.extension?translation` — pane routing is plausible, but anchor-level correctness was not fully verified in a shipping-safe way

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - grounded in local Apple SDK interfaces and current repository architecture
- Architecture: MEDIUM-HIGH - strongly supported by codebase seams, but some Settings-window sizing/deep-link details still require manual validation
- Pitfalls: MEDIUM - source-of-truth and popup-regression risks are clear; translation-pane deep-link behavior is still partly unverified

**Research date:** 2026-03-15
**Valid until:** 2026-04-14

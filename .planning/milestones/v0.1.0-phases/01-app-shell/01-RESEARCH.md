# Phase 1: App Shell - Research

**Researched:** 2026-03-14
**Domain:** Swift 6 / SwiftUI / macOS 15+ menu bar app scaffold
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Use an icon-only menu bar item in Phase 1; keep the visual direction quiet and native-looking.
- Menu bar item is visually static in Phase 1; no state-driven icon changes.
- Clicking the menu bar item opens a **standard dropdown menu**, not a custom popover.
- Menu is intentionally minimal: `Settings…` and `Quit` only. No header row or status row.
- On first launch the app starts quietly in the menu bar — no welcome window, notification, or startup cue.
- Selecting `Settings…` opens a minimal native-feeling settings-style window (title + short matter-of-fact note).
- No Dock icon; no Cmd+Tab app switcher presence.
- macOS 15+ minimum deployment target.
- Swift-native, not Electron/Catalyst.

### Claude's Discretion
- Exact SF Symbol or icon treatment, as long as it stays icon-only, quiet, and native.
- Whether the accent preference is expressed now or deferred.
- Exact placeholder settings copy, spacing, and window size.
- Standard menu polish details (separators, keyboard equivalents, ordering) provided menu stays minimal.

### Deferred Ideas (OUT OF SCOPE)
- Real target-language controls and model management → Phase 4.
- Trigger monitoring, permission guidance, first-run onboarding → Phase 2.
- Visual state changes in the menu bar item.
- Auto-launch at login.
- NSPanel popup → Phase 2 (do not implement now; do not paint the scaffold into a corner).
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| APP-01 | User can access Transy from the macOS menu bar without a Dock icon | LSUIElement + MenuBarExtra + activation policy findings directly address this requirement |
</phase_requirements>

---

## Summary

Phase 1 establishes the irreversible configuration decisions for a macOS menu bar utility. The core challenge is combining three concerns that interact in subtle ways: (1) suppressing Dock and Cmd+Tab presence, (2) presenting a native dropdown menu from a menu bar icon, and (3) opening a settings-style window without re-activating the Dock entry. All three are well-supported by Apple's current SwiftUI + AppKit APIs and have clear canonical solutions for macOS 15+.

**SwiftUI's `MenuBarExtra` with `.menu` style** is the right foundation for the menu bar item. It gives a native pull-down menu, works with the SwiftUI `App` lifecycle, is macOS 13+ (well within the 15+ floor), and requires zero AppKit bridging for Phase 1. The SwiftUI `Settings` scene paired with the `openSettings` environment action (macOS 14+) provides the canonical settings-window path. `LSUIElement = YES` in Info.plist suppresses the Dock and Cmd+Tab presence — this is an Info.plist key, not an entitlement (common mistake). App Sandbox should be explicitly **disabled** in Phase 1 to leave all global keyboard-monitoring options open for Phase 2.

The scaffold should also introduce an `@NSApplicationDelegateAdaptor`-backed `AppDelegate` now, even if nearly empty. Phase 2 will need AppKit-level NSPanel presentation; wiring that hook in Phase 1 avoids rework. A lightweight `AppState` observable object should be the central coordinator all future phases attach to.

**Primary recommendation:** Use `@main struct TransyApp: App` + `MenuBarExtra("Transy", systemImage: "...", content: { MenuBarView() }).menuBarExtraStyle(.menu)` + `Settings { SettingsView() }` + `LSUIElement = YES` + `@NSApplicationDelegateAdaptor(AppDelegate.self)` — no Sandbox.

---

## Standard Stack

### Core

| Library / API | Version / OS | Purpose | Why Standard |
|---------------|-------------|---------|--------------|
| SwiftUI `MenuBarExtra` | macOS 13+ (used on 15+) | Menu bar icon + menu | Native SwiftUI lifecycle, `.menu` style produces standard pull-down |
| SwiftUI `Settings` scene | macOS 13+ | Settings window scene | Canonical SwiftUI settings path; pairs with `openSettings` env action |
| `NSApplicationDelegateAdaptor` | All macOS SwiftUI | Bridge to AppKit delegate | Required hook for Phase 2 NSPanel; zero cost now |
| AppKit `NSApplication` | All macOS | Activation policy | `.accessory` policy = no Dock, no Cmd+Tab |
| `LSUIElement` Info.plist key | macOS 10.0+ | Suppress Dock at launch | Must be set in Info.plist; runtime-only policy change still briefly shows Dock |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| SF Symbols (system images) | macOS 11+ | Menu bar icon image | Use `systemImage:` on MenuBarExtra for instant native look |
| `@Observable` macro | Swift 5.9 / macOS 14+ | App state coordinator | Central observable state shared across menu + future phases |
| `openSettings` env action | macOS 14+ | Open Settings scene from code | Use inside menu Button("Settings…") action |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `MenuBarExtra` (SwiftUI) | `NSStatusItem` (AppKit) | NSStatusItem gives more control but requires full AppKit bridge; unnecessary for Phase 1 minimal menu |
| `Settings` scene | Custom `WindowGroup` + `openWindow` | Custom WindowGroup works but bypasses SwiftUI's single-instance settings management and Cmd+, binding |
| `@Observable` | `ObservableObject` | `ObservableObject` works but `@Observable` is the Swift 5.9+ standard; both fine on macOS 15+ |

**Installation:** No third-party packages needed for Phase 1. Pure Apple SDK.

---

## Architecture Patterns

### Recommended Project Structure

```
Transy/
├── TransyApp.swift           # @main App entry: MenuBarExtra + Settings scenes + AppDelegate adaptor
├── AppDelegate.swift         # NSApplicationDelegate stub; Phase 2 attaches NSPanel here
├── AppState.swift            # @Observable coordinator; future trigger/popup/settings state goes here
├── MenuBar/
│   └── MenuBarView.swift     # SwiftUI content of the .menu style MenuBarExtra (Buttons)
├── Settings/
│   └── SettingsView.swift    # Placeholder settings content (title + note)
└── Resources/
    └── Assets.xcassets       # App icon (required), menu bar template images if using custom icon
```

> **Note:** `Info.plist` is auto-generated by Xcode for Swift Package Manager or modern Xcode targets. `LSUIElement` is added as a custom key in the target's Info settings or directly in a custom Info.plist.

### Pattern 1: App Entry Point + No-Dock Configuration

**What:** Declare the SwiftUI App struct with MenuBarExtra and Settings scenes. Set LSUIElement in Info.plist. Attach AppDelegate adaptor for future AppKit bridging.
**When to use:** This is the single canonical entry point — every other scene and coordinator branches from here.

```swift
// Source: Apple Developer Documentation - MenuBarExtra, Settings, NSApplicationDelegateAdaptor
import SwiftUI

@main
struct TransyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra("Transy", systemImage: "character.bubble") {
            MenuBarView()
                .environmentObject(appState)
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView()
        }
    }
}
```

**Info.plist custom key (in Xcode target Info tab or Info.plist file):**
```xml
<key>LSUIElement</key>
<true/>
```

### Pattern 2: MenuBar Menu Content

**What:** Pure SwiftUI view that provides the dropdown menu items. `.menu` style renders its `View` content as native NSMenu items automatically.
**When to use:** All menu items in Phase 1. Button actions use environment values.

```swift
// Source: Apple Developer Documentation - MenuBarExtra / PullDownMenuBarExtraStyle
import SwiftUI

struct MenuBarView: View {
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Button("Settings…") {
            openSettings()
        }
        Divider()
        Button("Quit Transy") {
            NSApplication.shared.terminate(nil)
        }
    }
}
```

> `openSettings` is available macOS 14+. Targeting macOS 15+, this is unconditionally safe.

### Pattern 3: AppDelegate Stub

**What:** Minimal `NSApplicationDelegate` that does nothing in Phase 1 but provides the hook Phase 2 needs to present NSPanel without reworking the app entry point.
**When to use:** Always wire in Phase 1, even empty.

```swift
// Source: Apple NSApplicationDelegate protocol docs
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Phase 2: attach trigger monitor here
        // Phase 2: configure NSPanel here
    }
}
```

### Pattern 4: Observable App State Coordinator

**What:** `@Observable` class that will grow to hold trigger state, popup visibility, and settings. Centralized so menu, popup, and coordinator all share the same instance via environment.

```swift
// Source: Swift @Observable documentation (Swift 5.9+, macOS 14+)
import Observation

@Observable
final class AppState {
    // Phase 1: empty coordinator
    // Phase 2: var isPopupVisible = false; var triggerMonitor: HotkeyMonitor?
    // Phase 4: var targetLanguage: Locale.Language = .init(identifier: "ja")
}
```

> Use `@StateObject` at the App level if targeting macOS 13 (uses `ObservableObject`). On macOS 15+, `@Observable` + `@State` is cleaner and preferred.

### Pattern 5: Placeholder Settings View

**What:** Minimal SwiftUI view with a title and a single descriptive line. No controls, no branding.

```swift
import SwiftUI

struct SettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Transy")
                .font(.headline)
            Text("Settings will be available in a future update.")
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(width: 320, height: 120)
    }
}
```

### Anti-Patterns to Avoid

- **Setting activation policy at runtime only:** `NSApp.setActivationPolicy(.accessory)` at runtime still causes a brief Dock flash on launch. `LSUIElement = YES` in Info.plist is the correct, flash-free method. The runtime call is useful as a secondary belt-and-suspenders but not a replacement.
- **Using `.window` style on MenuBarExtra:** This renders a custom SwiftUI popover, not a native dropdown. Use `.menu` style for Phase 1's Settings + Quit dropdown.
- **Using `WindowGroup` for the settings window:** WindowGroup does not get single-instance management from SwiftUI automatically. It also doesn't bind to Cmd+,. Use `Settings` scene.
- **Placing App Sandbox = YES:** App Sandbox blocks `NSEvent.addGlobalMonitorForEvents` in Phase 2. Don't enable it in Phase 1 — leave the option open.
- **Not including `@NSApplicationDelegateAdaptor`:** Skipping it now means adding it later causes an App entry point refactor. Wire it in now even if the delegate is empty.
- **SwiftUI WindowGroup for the popup (future):** STATE.md explicitly calls this out — NSPanel is required for the Phase 2 non-activating popup, not WindowGroup.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Menu bar icon + dropdown | Custom NSStatusItem + NSMenu | `MenuBarExtra(.menu)` | Apple handles menu-item rendering, sizing, dark/light mode, user removal |
| Settings window lifecycle | Custom NSWindow + open/close tracking | `Settings` scene + `openSettings` | SwiftUI manages single-instance, Cmd+, binding, and window lifecycle |
| No-Dock suppression | Runtime-only `setActivationPolicy` | `LSUIElement = YES` in Info.plist | Info.plist method is the documented standard; avoids Dock flash |
| SF Symbol template icon | Custom-drawn menu bar icon | `systemImage:` on MenuBarExtra | Automatic template rendering, correct sizing, dark/light adaptation |
| App-wide state propagation | Singletons / globals | `@Observable AppState` injected via SwiftUI environment | Type-safe, testable, no hidden dependencies |

**Key insight:** In this domain, every custom solution either re-invents what Apple has already solved (menus, windows, policy) or creates a hard-to-undo architectural choice. The canonical SwiftUI approach is the path of least future regret.

---

## Common Pitfalls

### Pitfall 1: LSUIElement in the Wrong Place
**What goes wrong:** Developer sets `NSApp.setActivationPolicy(.accessory)` in `applicationDidFinishLaunching` but skips Info.plist `LSUIElement`. The app still briefly shows in the Dock on launch before the runtime call fires.
**Why it happens:** The runtime call fires after the app's first window/scene is already rendered, which triggers a momentary Dock entry.
**How to avoid:** Always set `LSUIElement = YES` (Boolean YES) in Info.plist. Optionally also set policy at runtime as belt-and-suspenders, but Info.plist is the primary mechanism.
**Warning signs:** Dock icon appears for ~0.5s on every launch.

### Pitfall 2: App Sandbox Blocks Phase 2
**What goes wrong:** Developer enables App Sandbox (`com.apple.security.app-sandbox = YES`) in Phase 1 entitlements. Phase 2 global key monitoring (`NSEvent.addGlobalMonitorForEvents`) silently fails or crashes because sandboxed apps cannot receive key events from other processes.
**Why it happens:** Global keyboard monitoring is an Accessibility-guarded API that is additionally blocked by App Sandbox boundaries.
**How to avoid:** Leave App Sandbox disabled (the default for non-App Store distribution). STATE.md already flags this validation requirement.
**Warning signs:** `addGlobalMonitorForEvents` handler never fires even after Accessibility permission granted.

### Pitfall 3: Settings Window Causes Dock Icon
**What goes wrong:** Opening the Settings window (or any NSWindow/WindowGroup window) causes the app to briefly re-enter `.regular` activation policy, showing a Dock icon while the window is open.
**Why it happens:** SwiftUI `WindowGroup` used incorrectly, or developer manually opens an NSWindow with `makeKeyAndOrderFront` without maintaining the accessory policy.
**How to avoid:** Use the `Settings` scene (not WindowGroup). If manually managing, call `NSApp.setActivationPolicy(.accessory)` after bringing the window forward. The Settings scene handles this correctly for LSUIElement apps.
**Warning signs:** Dock icon appears when Settings window is open.

### Pitfall 4: `.menu` vs `.window` Style Confusion
**What goes wrong:** Developer uses `.window` style (default for some inits) which renders a custom popover, not a native dropdown menu. The `Button` items don't behave like standard menu items.
**Why it happens:** `MenuBarExtra` defaults to `.automatic` which may render as a window on newer macOS versions if the content isn't recognized as menu-shaped.
**How to avoid:** Explicitly declare `.menuBarExtraStyle(.menu)` on the scene. This forces native pull-down behavior.
**Warning signs:** Clicking the menu bar icon opens a floating rounded-rectangle panel instead of a dropdown.

### Pitfall 5: MenuBarExtra Auto-Quit on Removal
**What goes wrong:** If using the non-`isInserted:` initializer for `MenuBarExtra`, when the user removes the menu bar item from the menu bar (by Cmd+dragging), the app automatically quits.
**Why it happens:** The Apple docs note: "When this item is removed from the system menu bar by the user, the application will be automatically quit." This is by design for the simple initializer.
**How to avoid:** For Phase 1, this is acceptable behavior (it mirrors the pattern of apps like Bartender targets). But if you want to allow hiding without quitting, use the `isInserted:` binding variant. For now, the simple init is fine.
**Warning signs:** App process terminates when user removes menu bar icon.

### Pitfall 6: Swift 6 Concurrency Isolation
**What goes wrong:** Swift 6 strict concurrency checking flags AppKit/SwiftUI UI calls not made on `@MainActor`, causing compile errors or runtime warnings.
**Why it happens:** Swift 6 enforces actor isolation at compile time. AppKit objects (NSApplication, NSWindow) must be accessed on the main actor.
**How to avoid:** Mark `AppDelegate` and `AppState` with `@MainActor`. Use `await MainActor.run { }` for any background-to-UI transitions (relevant in Phase 3+ for translation callbacks).
**Warning signs:** Swift 6 compiler errors: "Expression is not concurrency-safe because it refers to…"

---

## Code Examples

Verified patterns from official sources:

### Complete App Entry Point
```swift
// Source: Apple Developer Documentation - MenuBarExtra + NSApplicationDelegateAdaptor
import SwiftUI

@main
struct TransyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("Transy", systemImage: "character.bubble") {
            MenuBarView()
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView()
        }
    }
}
```

### Info.plist Key (Xcode Target Info tab or Info.plist)
```xml
<key>LSUIElement</key>
<true/>
```
> Source: Apple Developer Documentation - `LSUIElement` Info.plist key, macOS 10.0+
> "A Boolean value indicating whether the app is an agent app that runs in the background and doesn't appear in the Dock."

### Menu Content with Settings + Quit
```swift
// Source: Apple Developer Documentation - openSettings (macOS 14+), MenuBarExtra content
import SwiftUI

struct MenuBarView: View {
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Button("Settings…") {
            openSettings()
        }
        .keyboardShortcut(",", modifiers: .command)

        Divider()

        Button("Quit Transy") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
    }
}
```

### SF Symbol Selection for Menu Bar
```swift
// Common quiet, native-looking choices for a translation utility:
// "character.bubble"          — speech bubble with character (translation feel)
// "globe"                     — simple globe (language feel)
// "text.bubble"               — text in bubble
// "a.circle"                  — letter A in circle (minimal)
// All render as template images (automatic dark/light adaptation) via systemImage:
MenuBarExtra("Transy", systemImage: "character.bubble") { ... }
```

### AppDelegate Stub (Phase 1 — minimal, Phase 2 ready)
```swift
import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Reinforce activation policy (belt-and-suspenders alongside LSUIElement)
        NSApp.setActivationPolicy(.accessory)
    }
}
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| AppKit `NSStatusItem` + `NSMenu` + `NSApplicationDelegate` only | SwiftUI `MenuBarExtra(.menu)` + `App` protocol | macOS 13 (2022) | Full SwiftUI lifecycle; no AppKit bridging needed for simple menus |
| Manual `NSPreferencesWindowController` | SwiftUI `Settings` scene | macOS 12 (2021) | Single-instance settings management built into SwiftUI |
| `ObservableObject` + `@StateObject` | `@Observable` macro + `@State` | Swift 5.9 / macOS 14 (2023) | Less boilerplate, granular observation, no `@Published` needed |
| `openSettingsLegacy` / `NSApp.sendAction(#selector(showPreferences:))` | `@Environment(\.openSettings)` | macOS 14 (2023) | Type-safe SwiftUI way to open the Settings scene |

**Deprecated/outdated:**
- `NSPreferencesWindowController`: replaced by SwiftUI `Settings` scene; don't use for new code
- `@Published` + `ObservableObject`: still works but `@Observable` is the current pattern for new macOS 14+ code (macOS 15 is our floor)
- `showPreferences:` AppKit action: replaced by `openSettings` env action on macOS 14+

---

## Open Questions

1. **Sandbox strategy — validate in Phase 1**
   - What we know: App Sandbox blocks global keyboard monitoring; STATE.md says "validate in Phase 1 before locking final sandbox config"
   - What's unclear: Whether App Store distribution is a goal (if so, sandbox is required and global monitoring path must be reconsidered in Phase 2)
   - Recommendation: Phase 1 should ship **without** App Sandbox and document the explicit decision with rationale. Phase 2 will validate the monitoring approach and lock the sandbox policy.

2. **Icon treatment**
   - What we know: Must be icon-only, quiet, native. SF Symbols are the standard approach.
   - What's unclear: Which specific SF Symbol (Claude's discretion per CONTEXT.md).
   - Recommendation: Start with `"character.bubble"` — it reads as translation-related without being aggressive. Easy to swap.

3. **Settings window and activation policy on macOS 15**
   - What we know: `Settings` scene + LSUIElement works correctly in practice.
   - What's unclear: Whether macOS 15 introduced any behavioral changes to settings window + accessory policy interaction.
   - Recommendation: Manual validation step in Phase 1: open Settings → confirm no Dock icon appears → close → confirm still no Dock icon.

---

## Validation Architecture

> `workflow.nyquist_validation` is `true` in `.planning/config.json` — section included.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | XCTest (built into Xcode) |
| Config file | None needed — standard Xcode test target |
| Quick run command | `xcodebuild test -scheme Transy -destination 'platform=macOS' -only-testing:TransyTests 2>&1 \| tail -20` |
| Full suite command | `xcodebuild test -scheme Transy -destination 'platform=macOS' 2>&1 \| tail -30` |

> Note: Phase 1 is primarily structural/configuration. Most validations for this phase are **manual smoke tests**, not automated unit tests. Automated tests are added in this phase to establish the test target that later phases will populate.

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command / Note | File Exists? |
|--------|----------|-----------|--------------------------|-------------|
| APP-01 | App runs without crash on launch | Smoke | `xcodebuild build -scheme Transy` clean build | ❌ Wave 0 |
| APP-01 | No Dock icon present at runtime | Manual | Launch app → verify Dock, manual only | Manual only |
| APP-01 | Menu bar item appears | Manual | Launch app → check menu bar icon | Manual only |
| APP-01 | Menu shows Settings + Quit | Manual | Click menu bar icon → verify items | Manual only |
| APP-01 | Settings… opens placeholder window | Manual | Click Settings… → verify window opens | Manual only |
| APP-01 | Quit exits app cleanly | Manual | Click Quit → verify process gone | Manual only |
| APP-01 | No entitlement/sandbox errors in Console | Manual | `Console.app` → filter "Transy" on launch | Manual only |
| APP-01 | No Dock icon when Settings window open | Manual | Open Settings → look for Dock icon | Manual only |

### Sampling Rate
- **Per task commit:** `xcodebuild build -scheme Transy -destination 'platform=macOS'` (clean build passes)
- **Per wave merge:** Build + manual smoke checklist (all 7 manual checks above pass)
- **Phase gate:** Full manual checklist green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `TransyTests/TransyTests.swift` — test target stub (build verification, process exists check)
- [ ] `TransyUITests/TransyUITests.swift` — UI test target stub for future phases
- [ ] Xcode project with correct test scheme must be created as part of Plan 01-01

*(Infrastructure is the Wave 0 deliverable for Phase 1 — no tests exist yet because no Xcode project exists yet.)*

---

## Sources

### Primary (HIGH confidence)
- Apple Developer Documentation: `MenuBarExtra` — https://developer.apple.com/documentation/swiftui/menubarextra (confirmed macOS 13+, `.menu` style available)
- Apple Developer Documentation: `MenuBarExtraStyle` / `PullDownMenuBarExtraStyle` — pull-down menu renders native NSMenu
- Apple Developer Documentation: `LSUIElement` Info.plist key — "agent app that runs in the background and doesn't appear in the Dock" (macOS 10.0+)
- Apple Developer Documentation: `NSApplication.ActivationPolicy.accessory` — "doesn't appear in the Dock…corresponds to `LSUIElement`"
- Apple Developer Documentation: `Settings` scene — SwiftUI settings window management
- Apple Developer Documentation: `OpenSettingsAction` — macOS 14.0+, confirmed available on our macOS 15+ floor
- Apple Developer Documentation: `TranslationSession` — macOS 15.0+, confirms our deployment target floor
- Apple Developer Documentation: `NSEvent.addGlobalMonitorForEvents` — "Key-related events may only be monitored if accessibility is enabled or if your application is trusted for accessibility access"

### Secondary (MEDIUM confidence)
- Apple Developer Documentation: `NSApplicationDelegateAdaptor` — documented SwiftUI bridge to AppKit delegate
- Apple Developer Documentation: `@Observable` macro — macOS 14+, confirmed available on our floor

### Tertiary (LOW confidence — architectural pattern, not API)
- General Swift community pattern: `@NSApplicationDelegateAdaptor` hook for NSPanel in menu bar apps — widely used but not explicitly documented by Apple as "the" pattern for Phase 2 NSPanel readiness

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all APIs verified directly against Apple developer documentation JSON endpoints
- Architecture: HIGH — patterns derived from official API behavior; project structure is conventional Swift/Xcode
- Pitfalls: HIGH for items marked in STATE.md (LSUIElement vs entitlement, NSPanel requirement); MEDIUM for sandbox/Phase 2 interaction (needs Phase 1 validation)
- Translation framework macOS 15 floor: HIGH — `TranslationSession` is macOS 15.0+ per official docs

**Research date:** 2026-03-14
**Valid until:** 2026-09-14 (stable APIs; 6 months; re-verify if Xcode major version ships)

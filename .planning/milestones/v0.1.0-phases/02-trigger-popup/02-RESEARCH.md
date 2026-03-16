# Phase 2: Trigger & Popup — Research

**Researched:** 2026-03-14
**Domain:** macOS global keyboard monitoring, NSPanel popup, NSPasteboard capture/restore, Accessibility permissions
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Permission Guidance Flow**
- Do not show permission guidance on first launch.
- Show permission guidance the first time a trigger attempt fails because the required monitoring permission is missing.
- Present the guidance as a small dedicated guidance window rather than an alert or menu popover.
- Keep the guidance copy short and matter-of-fact.
- If permissions are still missing, show the guidance window again on each failed trigger attempt rather than suppressing it after the first dismissal.

**Popup Placement**
- Phase 2 uses a fixed placement rule; near-selection or near-cursor positioning is deferred.
- Show the popup on the active screen.
- Place it near the top-center of that screen.
- Use a subtle fade-in rather than a strong motion effect.
- If the trigger fires again in quick succession, reuse the same popup position and replace its contents instead of stacking multiple popups.

**Popup Visual Density**
- Keep the popup as a compact card rather than a larger reading panel.
- Show the source text in a readable form with a subtle muted/loading treatment rather than a heavy skeleton effect.
- For longer text, show a few lines and then truncate rather than letting the popup grow aggressively.
- Keep the popup content-only in Phase 2: no Transy label, extra chrome, or additional loading indicator.

**Trigger Miss Feedback**
- If the trigger fires but selected text cannot be captured, stay silent in Phase 2.
- Visible feedback should appear only when permission guidance is required.
- The trigger should feel invisible unless it actually succeeds.
- If permissions are fine but a single capture attempt fails, keep the app fully silent rather than showing a hint.

### Claude's Discretion
- Exact monitoring API choice, timing thresholds, repeat filtering, and clipboard-restore implementation details.
- Exact popup dimensions, typography, corner radius, and spacing as long as the popup stays compact and content-first.
- Exact wording of the permission guidance steps beyond the requested short, matter-of-fact tone.
- Exact screen insets, animation timing, and truncation thresholds as long as the popup remains top-center on the active screen.

### Deferred Ideas (OUT OF SCOPE)
- Positioning the popup near the selected text or mouse cursor belongs to a later UI refinement phase (`UI-01` in requirements).
- Showing translated output in the popup belongs to Phase 3.
- Real target-language controls and model-management UX belong to Phase 4.
- Any visible feedback for non-permission trigger misses remains deferred unless Phase 2 validation shows silence is too confusing.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| TRIG-01 | User can trigger translation of selected text by pressing `Command+C` twice within the supported interval | NSEvent global monitor on `.keyDown`, keyCode 8 + `.command` modifier, `DoublePressDetector` with ~400ms gate |
| TRIG-02 | User is guided to grant the required macOS permissions when the trigger cannot monitor key events | `AXIsProcessTrusted()` check before monitoring starts; `GuidanceWindowController` shown on first failed trigger attempt |
| TRIG-03 | User can keep their previous clipboard contents after translation is triggered | `ClipboardManager` saves clipboard at second Cmd+C, reads after 80ms delay, restores on popup dismiss |
| POP-01 | User sees a floating translation popup that does not take focus away from the current app | `NSPanel` with `[.borderless, .nonActivatingPanel]` style mask; `orderFront(nil)` not `makeKeyAndOrderFront` |
| POP-02 | User sees the selected source text immediately in a muted loading-state style while translation is in progress | `NSHostingView` with SwiftUI view showing source text in `.secondary` foreground style; no heavy skeleton |
| POP-03 | User can dismiss the popup with `Escape` or by clicking outside it | Global `NSEvent` monitors for `.keyDown` (keyCode 53) and `.leftMouseDown` outside panel frame |
</phase_requirements>

---

## Summary

Phase 2 wires up the double-`Command+C` trigger and floating popup on a foundation that Phase 1 already prepared. The monitoring API decision is clear: `NSEvent.addGlobalMonitorForEvents(matching: .keyDown)` is the correct AppKit-layer approach for a non-sandboxed menu bar agent. It runs on the main thread, requires only Accessibility permission (not Input Monitoring), and is well-understood on macOS 15. No external SPM packages are needed — the entire phase is pure AppKit + SwiftUI.

The three hardest problems in this phase are: (1) clipboard timing — the source app has not finished writing to NSPasteboard when the monitor fires, requiring a deliberate 80ms delay before reading; (2) non-focus-stealing popup — NSPanel with `.nonActivatingPanel` is correct but requires careful attention to the `makeKeyAndOrderFront` vs `orderFront` distinction and global event monitors for Escape/click-outside; (3) screen detection without being frontmost — since Transy is not the active app at trigger time, `NSScreen.main` may not be reliable, so the mouse-cursor position is the best proxy for "active screen."

The architecture slots naturally into the existing `AppDelegate`/`AppState` hook comments from Phase 1. Five new source files — `HotkeyMonitor`, `DoublePressDetector`, `ClipboardManager`, `PopupController`, `GuidanceWindowController` — implement all six requirements, and the existing `AppState` stubs (`isPopupVisible`, `triggerMonitor`) become real.

**Primary recommendation:** Use `NSEvent.addGlobalMonitorForEvents`, Accessibility only, 80ms clipboard delay, `NSPanel(.nonActivatingPanel)` with `NSHostingView`, mouse-cursor screen detection, and global event monitors for dismiss.

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `NSEvent` global monitor | AppKit (macOS 15+) | Detect Cmd+C key events across all apps | Only option at the AppKit layer; requires only Accessibility, runs on main thread, no CGEventTap complexity |
| `NSPanel` | AppKit (macOS 15+) | Non-focus-stealing floating window | The only window class designed for transient utility popups; `.nonActivatingPanel` is the standard solution |
| `NSHostingView` | SwiftUI/AppKit bridge (macOS 15+) | Host SwiftUI content inside NSPanel | Standard bridge; `NSHostingController` is an alternative but bare `NSHostingView` is simpler for a panel contentView |
| `NSPasteboard` | AppKit (macOS 15+) | Read selected text; save/restore clipboard | The only clipboard API in the AppKit layer |
| `AXIsProcessTrusted()` | ApplicationServices (macOS 15+) | Check Accessibility permission state | The official API; no Info.plist key needed; check-only (no system prompt) matches the deferred-guidance flow |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `NSWorkspace.shared.open(_:)` | AppKit (macOS 15+) | Open System Settings to Accessibility pane | Used in GuidanceWindowController "Open System Settings" button |
| `NSAnimationContext` | AppKit (macOS 15+) | Fade-in animation for NSPanel | Use for `alphaValue` 0→1 transition on panel show; `withAnimation` in SwiftUI does not animate NSPanel-level properties |
| `NSVisualEffectView` / `.regularMaterial` | AppKit/SwiftUI (macOS 15+) | Panel background material | Optional; `.background(.regularMaterial, in: RoundedRectangle(...))` in SwiftUI is the cleaner approach |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `NSEvent` global monitor | `CGEventTap` | CGEventTap is lower-level, can intercept/modify events, but adds complexity and may require Input Monitoring on some macOS versions; unnecessary here |
| `NSEvent` global monitor | `IOKit HID` | Requires Input Monitoring permission; much more complex; wrong abstraction level for a simple double-keypress detector |
| `NSPanel(.nonActivatingPanel)` | Borderless `NSWindow` at `.floating` level | NSWindow without nonActivatingPanel steals focus on `makeKeyAndOrderFront`; requires extra activation-policy gymnastics to prevent focus steal |
| `AXIsProcessTrusted()` no-prompt | `AXIsProcessTrustedWithOptions(prompt:true)` | The system prompt is generic and bypasses the custom guidance window that the user specified; use the no-prompt version and drive users to GuidanceWindowController instead |

**Installation:** No `npm install` — pure Swift. No new SPM dependencies for Phase 2.

---

## Architecture Patterns

### Recommended Project Structure

New files added under the existing `Transy/` source root (auto-discovered by xcodegen's `sources: path: Transy`):

```
Transy/
├── App/
│   ├── TransyApp.swift          (existing — Phase 1)
│   └── AppDelegate.swift        (existing — Phase 1; Phase 2 wires monitor + popup)
├── AppState.swift               (existing — Phase 1; Phase 2 activates stubs)
├── MenuBar/
│   └── MenuBarView.swift        (existing — Phase 1; no changes in Phase 2)
├── Settings/
│   └── SettingsView.swift       (existing — Phase 1; no changes in Phase 2)
├── Trigger/                     ← NEW in Phase 2
│   ├── HotkeyMonitor.swift
│   ├── DoublePressDetector.swift
│   └── ClipboardManager.swift
├── Popup/                       ← NEW in Phase 2
│   ├── PopupController.swift
│   └── PopupView.swift
└── Permissions/                 ← NEW in Phase 2
    └── GuidanceWindowController.swift
```

> **xcodegen note:** No changes to `project.yml` are needed — `sources: path: Transy` already recursively picks up all new `.swift` files.

### Pattern 1: NSEvent Global Monitor for Key Events

**What:** Register a global event monitor for `.keyDown`. The handler is called on the main thread. Filter for Cmd+C (keyCode 8, `.command` modifier, `!isARepeat`). Delegate timing logic to `DoublePressDetector`.

**When to use:** The app is not frontmost; local monitors would never fire. Global monitors fire for all apps.

```swift
// Source: Apple Developer Documentation — NSEvent.addGlobalMonitorForEvents(matching:handler:)
// Confirmed: runs on main thread, requires Accessibility, returns opaque Any? token

@MainActor
final class HotkeyMonitor {
    private var monitor: Any?

    func start() {
        monitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handle(event)
        }
    }

    func stop() {
        if let m = monitor { NSEvent.removeMonitor(m); monitor = nil }
    }

    private func handle(_ event: NSEvent) {
        // Filter: must be Cmd+C, not key-repeat
        guard event.modifierFlags.intersection(.deviceIndependentFlagsMask) == .command,
              event.keyCode == 8,           // physical 'c' key
              !event.isARepeat else { return }
        // ... hand off to DoublePressDetector
    }
}
```

**Critical detail:** `event.modifierFlags.intersection(.deviceIndependentFlagsMask) == .command` — use the intersection to strip caps lock and other transient bits. Checking `.contains(.command)` alone will match Cmd+Shift+C, which should NOT trigger.

### Pattern 2: DoublePressDetector — Timestamp Gate

**What:** Stateful struct tracking the last Cmd+C press time. Returns `true` only if a press occurs within the threshold of the previous press.

```swift
// Source: standard macOS double-press detection pattern
// Threshold: ~400ms matches the Phase 2 success criterion

struct DoublePressDetector {
    private(set) var lastPressDate: Date?
    let threshold: TimeInterval = 0.4

    /// Returns true if this press counts as the second press of a double-press gesture.
    mutating func record() -> Bool {
        let now = Date()
        defer { lastPressDate = now }
        guard let last = lastPressDate else { return false }
        let isDouble = now.timeIntervalSince(last) < threshold
        if isDouble { lastPressDate = nil }   // reset after firing
        return isDouble
    }
}
```

**Important:** Reset `lastPressDate` to `nil` after a double-press fires so rapid triple-press does not fire twice.

### Pattern 3: Clipboard Save/Restore with Timing Delay

**What:** At the moment the second Cmd+C is detected, snapshot the current clipboard before the source app writes the new selection. Wait 80ms. Read the new content. Restore on popup dismiss.

**Why 80ms:** The NSEvent monitor fires on `.keyDown`. The source app processes the keyDown event and writes to `NSPasteboard.general` some milliseconds later. 80ms is a conservative safe interval, consistent with industry practice for clipboard-capture utilities and noted explicitly in this project's STATE.md.

```swift
// Source: STATE.md "Clipboard read must be delayed ~80ms after trigger fires"
// Pattern: save → delay → read → (later) restore

@MainActor
final class ClipboardManager {

    // Called immediately at second Cmd+C detection (before source app writes)
    func saveCurrentContents() -> [NSPasteboardItem] {
        let pb = NSPasteboard.general
        return (pb.pasteboardItems ?? []).compactMap { item in
            let copy = NSPasteboardItem()
            for type in item.types {
                if let data = item.data(forType: type) {
                    copy.setData(data, forType: type)
                }
            }
            return copy
        }
    }

    // Called 80ms after trigger
    func readSelectedText() -> String? {
        return NSPasteboard.general.string(forType: .string)
    }

    // Called on popup dismiss
    func restore(_ savedItems: [NSPasteboardItem]) {
        let pb = NSPasteboard.general
        pb.clearContents()
        if !savedItems.isEmpty {
            pb.writeObjects(savedItems)
        }
    }
}
```

**Full trigger sequence:**
```swift
// On second Cmd+C detected
let saved = clipboardManager.saveCurrentContents()
Task { @MainActor in
    try? await Task.sleep(for: .milliseconds(80))
    guard let text = clipboardManager.readSelectedText(), !text.isEmpty else {
        // Permissions OK but no text captured — stay silent (CONTEXT.md requirement)
        clipboardManager.restore(saved)
        return
    }
    popupController.show(sourceText: text, onDismiss: {
        clipboardManager.restore(saved)
    })
}
```

### Pattern 4: Non-Activating NSPanel with SwiftUI Content

**What:** `NSPanel` with `[.borderless, .nonActivatingPanel]` style mask. Use `orderFront(nil)` — never `makeKeyAndOrderFront`. Host SwiftUI via `NSHostingView`.

```swift
// Source: Apple Developer Documentation — NSPanel, NSWindowStyleMask.nonActivatingPanel
// Confirmed: .nonActivatingPanel prevents the *app* from activating; the panel can still float above other windows

@MainActor
final class PopupController {
    private lazy var panel: NSPanel = makePanel()
    private var dismissMonitors: [Any] = []
    private var onDismiss: (() -> Void)?

    private func makePanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 1),  // height auto-sizes
            styleMask: [.borderless, .nonActivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false     // CRITICAL: must not hide when source app regains focus
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        return panel
    }

    func show(sourceText: String, onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
        let view = PopupView(sourceText: sourceText)
        panel.contentView = NSHostingView(rootView: view)
        panel.setFrameOrigin(topCenterOrigin(for: panel))
        panel.alphaValue = 0
        panel.orderFront(nil)               // NOT makeKeyAndOrderFront — preserves source app focus
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.15
            panel.animator().alphaValue = 1
        }
        attachDismissMonitors()
    }

    func dismiss() {
        removeDismissMonitors()
        panel.orderOut(nil)
        onDismiss?()
        onDismiss = nil
    }
}
```

**`hidesOnDeactivate = false` is mandatory.** The default `true` causes the panel to vanish the instant the source app regains focus — exactly the scenario that happens naturally when the user has not interacted with Transy.

### Pattern 5: Dismiss on Escape and Outside Click via Global Monitors

**What:** Since the panel is non-activating and Transy is not the frontmost app, local event monitors will not fire for Escape or outside clicks. Use global monitors.

```swift
private func attachDismissMonitors() {
    let escMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
        if event.keyCode == 53 { self?.dismiss() }   // 53 = Escape
    }
    let clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
        guard let self, let panelFrame = self.panel.frame as NSRect? else { return }
        // NSEvent.mouseLocation is in screen coordinates (bottom-left origin)
        if !panelFrame.contains(NSEvent.mouseLocation) {
            self.dismiss()
        }
    }
    dismissMonitors = [escMonitor, clickMonitor].compactMap { $0 }
}

private func removeDismissMonitors() {
    dismissMonitors.forEach { NSEvent.removeMonitor($0) }
    dismissMonitors = []
}
```

**Remove monitors immediately on dismiss** — global monitors accumulate if not removed and will fire spuriously on subsequent interactions.

### Pattern 6: Active Screen Detection Without Frontmost Status

**What:** At trigger time, Transy is not the active app. `NSScreen.main` returns the screen with the current *key window*, which is typically the source app's screen — but it can be `nil` in edge cases. The most reliable proxy is the screen containing the mouse cursor.

```swift
// Source: Apple Developer Documentation — NSScreen, NSEvent.mouseLocation
// NSEvent.mouseLocation returns the current cursor position in screen coordinates (bottom-left origin, flipped from AppKit)

private func activeScreen() -> NSScreen {
    let cursor = NSEvent.mouseLocation
    return NSScreen.screens.first { NSMouseInRect(cursor, $0.frame, false) }
        ?? NSScreen.main
        ?? NSScreen.screens[0]
}

private func topCenterOrigin(for panel: NSPanel) -> NSPoint {
    let screen = activeScreen()
    let sf = screen.visibleFrame        // excludes menu bar at top and Dock at bottom
    let pw = panel.frame.width
    let ph = panel.frame.height
    let x = sf.midX - pw / 2
    let y = sf.maxY - ph - 24          // 24pt inset below the menu bar
    return NSPoint(x: x, y: y)
}
```

**`visibleFrame.maxY` is the y-coordinate just below the system menu bar.** `screen.frame.maxY` includes the menu bar area and would place the popup behind it.

### Pattern 7: Muted Source-Text Loading Style (NOT `.redacted`)

**What:** Show source text immediately in `.secondary` foreground style. This is the "readable muted/loading treatment" specified in CONTEXT.md. The heavy SwiftUI `.redacted(reason: .placeholder)` produces unreadable gray blobs and is explicitly NOT what the user wants.

```swift
// PopupView.swift
struct PopupView: View {
    let sourceText: String

    var body: some View {
        Text(sourceText)
            .font(.body)
            .foregroundStyle(.secondary)        // muted but readable
            .lineLimit(4)
            .truncationMode(.tail)
            .multilineTextAlignment(.leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(width: 380, alignment: .leading)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}
```

**In Phase 3,** `foregroundStyle(.secondary)` changes to `.primary` (or is removed) when the translation result replaces the source text.

### Pattern 8: Permission Check and Guidance Window

**What:** Check `AXIsProcessTrusted()` before starting the monitor. If false, `HotkeyMonitor.start()` silently does nothing. Show `GuidanceWindowController` on every failed trigger attempt (i.e., every time the trigger *would* have fired but can't because the monitor isn't running).

```swift
// Source: Apple Developer Documentation — AXIsProcessTrusted()
// Note: AXIsProcessTrustedWithOptions(prompt:true) is NOT used here because
// the user specified a custom guidance window rather than the system alert.

import ApplicationServices

@MainActor
final class GuidanceWindowController: NSWindowController {

    static let shared = GuidanceWindowController()

    func showIfNeeded() {
        guard !AXIsProcessTrusted() else { return }
        // Show or bring-to-front the guidance window
        if window == nil { loadWindow() }
        NSApp.activate()
        window?.makeKeyAndOrderFront(nil)
    }

    private func loadWindow() {
        // Build a small window with SwiftUI content
        let view = GuidanceView()
        let hosting = NSHostingController(rootView: view)
        hosting.view.frame = NSRect(x: 0, y: 0, width: 340, height: 180)
        let win = NSWindow(contentViewController: hosting)
        win.title = ""
        win.styleMask = [.titled, .closable]
        win.level = .floating
        self.window = win
    }
}
```

**System Settings URL for Accessibility (macOS 13+):**
```swift
NSWorkspace.shared.open(
    URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
)
```

This URL is the standard cross-version approach used by macOS utilities to deep-link into the Accessibility privacy pane. Confirmed working on macOS 13, 14, and expected to continue on 15.

### Pattern 9: AppDelegate Wiring

**What:** `AppDelegate.applicationDidFinishLaunching` is where the monitor starts and the popup controller is configured. The Phase 1 hook comments become real code.

```swift
// AppDelegate.swift — replaces Phase 1 hook comments
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    private let appState = AppState.shared        // or injected
    private let hotkeyMonitor = HotkeyMonitor()
    private let popupController = PopupController()
    private let clipboardManager = ClipboardManager()
    private let guidanceController = GuidanceWindowController.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)     // belt-and-suspenders (Phase 1 pattern)

        // Start monitoring only if Accessibility is granted; otherwise defer until first trigger attempt
        if AXIsProcessTrusted() {
            hotkeyMonitor.start(
                onDoubleCmdC: { [weak self] in self?.handleTrigger() }
            )
        }
        // Phase 2: HotkeyMonitor configured ✓
        // Phase 2: PopupController configured ✓
    }

    private func handleTrigger() {
        guard AXIsProcessTrusted() else {
            guidanceController.showIfNeeded()     // TRIG-02: show guidance on failed trigger
            return
        }
        let saved = clipboardManager.saveCurrentContents()
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(80))
            guard let text = clipboardManager.readSelectedText(), !text.isEmpty else {
                clipboardManager.restore(saved)
                return                            // silent miss — CONTEXT.md requirement
            }
            popupController.show(sourceText: text) {
                self.clipboardManager.restore(saved)
            }
        }
    }
}
```

### Anti-Patterns to Avoid

- **`makeKeyAndOrderFront(nil)` on the popup panel** — steals key window from the source app, breaking POP-01.
- **`NSWindow` instead of `NSPanel`** — standard `NSWindow` activates the app on appearance without explicit activation-policy tricks.
- **`hidesOnDeactivate = true` (the default)** — the popup instantly vanishes when the source app regains focus.
- **`.redacted(reason: .placeholder)` for the source text** — produces unreadable gray blobs, contradicts CONTEXT.md "readable muted treatment."
- **`AXIsProcessTrustedWithOptions(prompt:true)`** — shows a generic system alert instead of the custom guidance window.
- **Not removing global event monitors on dismiss** — monitors accumulate; every subsequent Escape or click fires stale handlers.
- **Reading clipboard immediately on `keyDown`** — source app has not written selection yet; results in empty or stale clipboard read.
- **`NSScreen.main` as active-screen proxy** — can be `nil` for an `LSUIElement` app with no visible windows; use mouse cursor instead.
- **`event.modifierFlags.contains(.command)` alone** — matches Cmd+Shift+C; use `.intersection(.deviceIndependentFlagsMask) == .command`.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Global key monitoring | Custom CGEventTap wrapper | `NSEvent.addGlobalMonitorForEvents` | CGEventTap adds Input Monitoring permission risk on some macOS versions; NSEvent is sufficient and simpler |
| Non-activating floating window | Custom `NSWindow` + activation gymnastics | `NSPanel([.borderless, .nonActivatingPanel])` | NSPanel is the purpose-built class for exactly this use case |
| Permission state check | Custom scripting bridge or IOKit polling | `AXIsProcessTrusted()` | The official, single-call check; no polling needed |
| Clipboard read/write | Custom UTI parser | `NSPasteboard.general.string(forType: .string)` and `writeObjects(_:)` | NSPasteboard API handles all edge cases; text string capture is trivial with the standard API |
| SwiftUI in NSPanel | Custom bridging code | `NSHostingView(rootView:)` | This is the standard AppKit/SwiftUI bridge; zero extra code |
| Fade animation on NSPanel | UIKit-style animation | `NSAnimationContext.runAnimationGroup` + `panel.animator().alphaValue` | NSAnimationContext is the AppKit-native way; SwiftUI `withAnimation` does not apply to NSPanel properties |

**Key insight:** Every problem in this phase has an official AppKit primitive. The risk is choosing the *wrong* primitive (e.g., `NSWindow` instead of `NSPanel`, `makeKeyAndOrderFront` instead of `orderFront`), not needing a custom solution.

---

## Common Pitfalls

### Pitfall 1: Reading Clipboard Before Source App Writes It

**What goes wrong:** `NSEvent` global monitor fires on `.keyDown` — at that instant the source app has received the event but not yet processed it. Reading `NSPasteboard.general` immediately yields the *previous* clipboard contents, not the selected text.

**Root cause:** App event processing is asynchronous relative to the global monitor callback.

**How to avoid:** Always wait at least 80ms after detecting the second Cmd+C before reading the pasteboard. Use `Task.sleep(for: .milliseconds(80))`. STATE.md explicitly documents this timing.

**Warning signs:** Popup shows the wrong text (whatever was in the clipboard before the selection), or an empty string.

---

### Pitfall 2: `hidesOnDeactivate = true` Makes the Popup Disappear Instantly

**What goes wrong:** After the popup opens, the source app naturally becomes frontmost again (user did not click Transy). The NSPanel immediately vanishes because `hidesOnDeactivate` defaults to `true`.

**Root cause:** `hidesOnDeactivate` is designed for inspector panels that should not distract when their owner app loses focus. For a cross-app utility popup, this behavior is wrong.

**How to avoid:** Set `panel.hidesOnDeactivate = false` during panel creation.

**Warning signs:** Popup flickers briefly and disappears immediately after appearing.

---

### Pitfall 3: Modifier Flag Matching is Too Broad

**What goes wrong:** `event.modifierFlags.contains(.command)` is true for Cmd+Shift+C, Cmd+Option+C, Cmd+Ctrl+C — all common shortcuts in text editors and IDEs. The trigger fires unexpectedly.

**Root cause:** `.contains` checks for the presence of the flag but ignores additional flags.

**How to avoid:** Use `event.modifierFlags.intersection(.deviceIndependentFlagsMask) == .command` to verify that Command is the *only* modifier active.

**Warning signs:** Translation popup appears randomly while using keyboard shortcuts in other apps.

---

### Pitfall 4: Caps Lock Causes Unexpected Flag Values

**What goes wrong:** On macOS, when Caps Lock is active, `modifierFlags` includes `.capsLock`. Without stripping non-device-independent flags, the Caps Lock + Cmd+C combination will fail the modifier check even though the user pressed the right keys.

**Root cause:** `NSEvent.modifierFlags` includes hardware-state bits beyond modifier keys.

**How to avoid:** Always intersect with `.deviceIndependentFlagsMask` before comparing.

---

### Pitfall 5: Global Dismiss Monitors Accumulate

**What goes wrong:** Each call to `show(sourceText:onDismiss:)` adds new global monitors for Escape and outside click. If dismiss is called (or the popup replaced) without removing prior monitors, they accumulate and fire spuriously.

**Root cause:** `NSEvent.addGlobalMonitorForEvents` returns a token; the monitors remain active until explicitly removed with `NSEvent.removeMonitor`.

**How to avoid:** Always call `removeDismissMonitors()` at the start of both `show()` (before attaching new ones) and `dismiss()`.

---

### Pitfall 6: NSPasteboardItem Data May Be Lazy

**What goes wrong:** `NSPasteboardItem` can use `NSPasteboardItemDataProvider` for deferred/lazy data. Calling `.data(forType:)` on a lazy item after the source app clears the pasteboard may return `nil`.

**Root cause:** NSPasteboard is a multi-process communication channel; items with data providers rely on the source app still owning the pasteboard.

**How to avoid:** Copy data from each item type immediately when saving (do not defer). Accept that some rich types (custom UTIs, large images) may not copy successfully and focus on `.string` as the primary type to preserve. For Phase 2 the clipboard's text content is the only thing that actually matters — the user triggered a text translation.

---

### Pitfall 7: `NSScreen.main` is Unreliable for LSUIElement Apps

**What goes wrong:** `NSScreen.main` is documented as the screen containing the key window. For an `LSUIElement` app with no visible windows, it may return the wrong screen or even `nil` during some startup windows.

**Root cause:** "Main screen" is defined relative to the key window, which Transy does not own at trigger time.

**How to avoid:** Use `NSScreen.screens.first { NSMouseInRect(NSEvent.mouseLocation, $0.frame, false) }` with a fallback to `NSScreen.main`. The mouse cursor is always on the screen the user is actively using.

---

### Pitfall 8: isARepeat Key Events Cause Phantom Triggers

**What goes wrong:** Holding Cmd+C generates repeated `.keyDown` events with `isARepeat = true`. These can satisfy the double-press threshold without the user intending two distinct presses.

**Root cause:** macOS generates key-repeat events at the system key-repeat rate after the initial key delay.

**How to avoid:** Filter `event.isARepeat == true` in the `HotkeyMonitor` handler — skip any event where `isARepeat` is set.

---

## Code Examples

### Full Modifier Flag Check

```swift
// Source: Apple Developer Documentation — NSEvent.modifierFlags, NSEventModifierFlags.deviceIndependentFlagsMask
// Strips caps lock, function key, and other hardware bits before comparing

let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
guard flags == .command else { return }
```

### Screen-Clamped Top-Center Frame

```swift
// Ensure popup stays within screen bounds even at unusual display sizes
private func popupFrame(width: CGFloat, height: CGFloat) -> NSRect {
    let screen = activeScreen()
    let sf = screen.visibleFrame
    let x = (sf.midX - width / 2).clamped(to: sf.minX...(sf.maxX - width))
    let y = sf.maxY - height - 24
    return NSRect(x: x, y: y, width: width, height: height)
}
// Requires: extension Comparable { func clamped(to range: ClosedRange<Self>) -> Self }
```

### Clipboard Deep Copy (Avoiding Lazy Data Pitfall)

```swift
// Source: NSPasteboardItem documentation
// Deep-copies all item types synchronously while source app still owns the pasteboard

func deepCopyItems() -> [NSPasteboardItem] {
    return (NSPasteboard.general.pasteboardItems ?? []).compactMap { item in
        let copy = NSPasteboardItem()
        var copied = false
        for type in item.types {
            if let data = item.data(forType: type) {
                copy.setData(data, forType: type)
                copied = true
            }
        }
        return copied ? copy : nil
    }
}
```

### Opening System Settings — Accessibility

```swift
// Source: standard macOS deep-link pattern, stable since macOS 13
NSWorkspace.shared.open(
    URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
)
```

### NSPanel Fade-In

```swift
// Source: NSAnimationContext documentation
// NSPanel-level properties are not animatable via SwiftUI withAnimation

panel.alphaValue = 0
panel.orderFront(nil)
NSAnimationContext.runAnimationGroup { context in
    context.duration = 0.15
    context.timingFunction = CAMediaTimingFunction(name: .easeOut)
    panel.animator().alphaValue = 1
}
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `System Preferences` deep-link URLs | Same `x-apple.systempreferences:` scheme (backward-compatible through macOS 15) | macOS 13 UI rename | URL scheme unchanged; still works |
| `CGEventTap` for global key monitoring in menu bar apps | `NSEvent.addGlobalMonitorForEvents` for AppKit-layer apps | Stable since macOS 10.6 | NSEvent approach is simpler, on-main-thread, no need for CGEventTap in non-intercepting use cases |
| `NSHostingController` as bridge | `NSHostingView` (for simple contentView use) or `NSHostingController` (for responder chain) | Stable | `NSHostingView` is simpler for panels where responder chain is handled by global monitors |
| `SMAppService` launch at login | — | macOS 13+ | Not in Phase 2 scope; noted for Phase 4 |

**Deprecated/outdated:**
- `SystemEventsApplicationProcess` scripting bridge: do not use for key monitoring — replaced by NSEvent global monitors.
- `NSStatusBar.system.statusItem(withLength:)` with `NSMenu`: replaced by SwiftUI `MenuBarExtra` in macOS 13+ — already handled in Phase 1.

---

## Open Questions

1. **80ms Clipboard Timing Threshold**
   - What we know: 80ms is the value documented in STATE.md and consistent with common macOS clipboard-capture utilities
   - What's unclear: Some slow or heavily loaded source apps may need more time; very fast apps may not need 80ms
   - Recommendation: Start with 80ms. If runtime testing shows misses, increase to 120ms. Design the delay as a named constant (`ClipboardManager.captureDelay`) so it can be adjusted without a code search.

2. **Pasteboard Content-Type Priority**
   - What we know: `NSPasteboard.string(forType: .string)` is sufficient for plain-text reading
   - What's unclear: Some apps write rich text (RTF, HTML) to the pasteboard first and plain text second. `string(forType:)` should still work, but the order of types in `pasteboardItems` may affect deep-copy fidelity.
   - Recommendation: For reading (capture), always use `.string` type. For saving/restoring, copy all types faithfully.

3. **Permission Re-Check After Grant**
   - What we know: `AXIsProcessTrusted()` can return `true` after a user grants permission in System Settings, but the *running* app does not automatically restart its monitor.
   - What's unclear: Whether the app needs explicit user action (quit & relaunch) or can start the monitor dynamically after permission is granted.
   - Recommendation: After showing the guidance window, start a periodic check (`DispatchQueue.main.asyncAfter` or a `Timer`) to re-check `AXIsProcessTrusted()` and auto-start the monitor when it becomes true, avoiding the need for a manual relaunch. Keep this implementation in `GuidanceWindowController`.

---

## Validation Architecture

> `workflow.nyquist_validation` is `true` in `.planning/config.json` — this section is required.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Swift Testing (already present in `TransyTests/TransyTests.swift` from Phase 1) |
| Config file | None — driven by `xcodebuild test` scheme |
| Quick run command | `xcodebuild test -scheme Transy -destination 'platform=macOS' -only-testing:TransyTests` |
| Full suite command | `xcodebuild test -scheme Transy -destination 'platform=macOS'` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| TRIG-01 | Double-press within 400ms triggers; single press does not; third press after reset does not double-trigger | unit | `xcodebuild test -scheme Transy -destination 'platform=macOS' -only-testing:TransyTests/DoublePressDetectorTests` | ❌ Wave 0 |
| TRIG-01 | isARepeat events are filtered and do not advance the double-press state | unit | `xcodebuild test -scheme Transy -destination 'platform=macOS' -only-testing:TransyTests/HotkeyMonitorTests` | ❌ Wave 0 |
| TRIG-01 | Modifier flag check rejects Cmd+Shift+C and Cmd+Option+C | unit | same as above | ❌ Wave 0 |
| TRIG-02 | `GuidanceWindowController.showIfNeeded()` shows window only when `AXIsProcessTrusted()` is false | manual | Human: launch app without Accessibility permission → press Cmd+C twice → guidance window appears | n/a (manual) |
| TRIG-03 | `ClipboardManager.saveCurrentContents()` deep-copies all pasteboard item types | unit | `xcodebuild test -scheme Transy -destination 'platform=macOS' -only-testing:TransyTests/ClipboardManagerTests` | ❌ Wave 0 |
| TRIG-03 | `ClipboardManager.restore()` writes saved items back, overwriting any intermediate content | unit | same as above | ❌ Wave 0 |
| POP-01 | Popup appears without Transy becoming the frontmost app; source app retains focus | manual | Human: open TextEdit with text, select, Cmd+C Cmd+C → popup appears → TextEdit remains active in Cmd+Tab | n/a (manual) |
| POP-02 | Popup shows source text in muted style immediately | manual | Human: visual verification that text appears in secondary/muted color | n/a (manual) |
| POP-03 | Escape key dismisses popup | manual | Human: open popup → press Escape → popup disappears | n/a (manual) |
| POP-03 | Click outside popup dismisses it | manual | Human: open popup → click elsewhere on screen → popup disappears | n/a (manual) |

### Sampling Rate
- **Per task commit:** `xcodebuild test -scheme Transy -destination 'platform=macOS' -only-testing:TransyTests`
- **Per wave merge:** `xcodebuild test -scheme Transy -destination 'platform=macOS'`
- **Phase gate:** All automated tests green + human smoke-test checklist passed before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `TransyTests/DoublePressDetectorTests.swift` — covers TRIG-01 timing logic (single press, double press within threshold, double press after threshold, triple press, isARepeat filtering)
- [ ] `TransyTests/ClipboardManagerTests.swift` — covers TRIG-03 save/restore round-trip
- [ ] `TransyTests/HotkeyMonitorTests.swift` — covers modifier flag matching (exact Cmd only, Cmd+Shift rejected, Cmd+Option rejected)

> The Swift Testing framework (`import Testing`) is already available in the project via Xcode 16. No new framework installation is needed. Add the new test files to `TransyTests/` and they will be auto-discovered.

---

## Sources

### Primary (HIGH confidence)

- Apple Developer Documentation: `NSEvent.addGlobalMonitorForEvents(matching:handler:)` — confirmed main-thread execution, Accessibility requirement, token-based removal
- Apple Developer Documentation: `NSPanel` and `NSWindowStyleMask.nonActivatingPanel` — confirmed behavior for floating utility panels
- Apple Developer Documentation: `AXIsProcessTrusted()` — confirmed as the check-only Accessibility status API
- Apple Developer Documentation: `NSPasteboard` and `NSPasteboardItem` — confirmed `.data(forType:)` for deep copy, `.writeObjects` for restore
- Apple Developer Documentation: `NSScreen.visibleFrame` vs `frame` — confirmed `visibleFrame` excludes menu bar and Dock
- Apple Developer Documentation: `NSEvent.mouseLocation` — confirmed returns cursor position in screen coordinates
- Phase 1 SUMMARY files and STATE.md — confirmed existing patterns (AppDelegate hooks, AppState stubs, `hidesOnDeactivate` pitfall documented)

### Secondary (MEDIUM confidence)

- STATE.md project note: "Clipboard read must be delayed ~80ms after trigger fires" — consistent with well-established macOS clipboard-capture practice
- Existing PITFALLS.md: confirmed all Phase 2 pitfalls already identified and documented
- Existing ARCHITECTURE.md: confirmed `NSPanel(.nonActivatingPanel)` + `NSHostingView` as the established popup pattern

### Tertiary (LOW confidence — flag for validation)

- `x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility` URL for macOS 15 System Settings deep-link — format is unchanged since macOS 13, expected to work on 15 but should be validated at runtime during plan 02-01

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all components are established AppKit APIs with no external dependencies
- Architecture: HIGH — component boundaries and integration points validated against Phase 1 code and existing research documents
- Pitfalls: HIGH — most pitfalls are already documented in project PITFALLS.md and STATE.md from pre-phase research
- Timing values (80ms): MEDIUM — value documented in STATE.md, consistent with macOS clipboard utility practice, but exact threshold may need runtime validation

**Research date:** 2026-03-14
**Valid until:** 2026-04-14 (stable AppKit APIs; no fast-moving dependencies)

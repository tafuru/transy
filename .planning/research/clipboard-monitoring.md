# NSPasteboard Monitoring as Translation Trigger

**Researched:** 2025-01-20
**Confidence:** HIGH (verified via Apple docs + Maccy open source + existing codebase analysis)

## Overview

NSPasteboard monitoring (clipboard polling) is a well-established macOS pattern used by clipboard manager apps like Maccy, Paste, and CopyClip. It works by polling `NSPasteboard.general.changeCount` on a timer — a simple integer that increments every time any app writes to the clipboard. This approach requires **no special permissions** (no Accessibility, no CGEvent tap), making it attractive as an alternative or complement to Transy's current double Cmd+C hotkey trigger.

## How It Works

### The changeCount Mechanism

`NSPasteboard.general.changeCount` is an integer property that the system increments each time any application calls `clearContents()` or `writeObjects()` on the general pasteboard. The standard pattern:

```swift
@MainActor
final class ClipboardWatcher {
    private var lastChangeCount: Int
    private var timer: Timer?

    init() {
        lastChangeCount = NSPasteboard.general.changeCount
    }

    func start() {
        timer = Timer.scheduledTimer(
            timeInterval: 0.5,  // Maccy default
            target: self,
            selector: #selector(checkClipboard),
            userInfo: nil,
            repeats: true
        )
    }

    @objc func checkClipboard() {
        let currentCount = NSPasteboard.general.changeCount
        guard currentCount != lastChangeCount else { return }
        lastChangeCount = currentCount

        // New clipboard content detected
        guard let text = NSPasteboard.general.string(forType: .string) else { return }
        handleNewClipboardText(text)
    }
}
```

### Detecting "New Content" vs "Same Content Re-Copied"

**`changeCount` increments even when identical content is re-copied.** This is important — if a user copies "hello" twice, `changeCount` will change both times. The polling approach cannot distinguish between "new text" and "same text copied again."

For Transy's purposes, this is actually **desirable**: each copy action should potentially trigger a translation, regardless of whether the text matches previous clipboard content.

If you _did_ need to distinguish, you'd hash the clipboard content and compare, but this adds complexity for no benefit in Transy's use case.

### Timer Interval: Responsiveness vs Battery

| Interval | Responsiveness | CPU Impact | Used By |
|----------|---------------|------------|---------|
| 0.1s | Near-instant (~100ms delay) | Noticeable on battery | — |
| 0.25s | Very responsive (~250ms) | Minimal | Some clipboard managers |
| 0.5s | Good (~500ms) | Negligible | **Maccy (default)** |
| 1.0s | Acceptable (~1s) | None | Conservative apps |
| 2.0s | Sluggish | None | Background monitoring |

**Recommendation: 0.5s** (matching Maccy's battle-tested default). This gives a worst-case 500ms delay between the user pressing Cmd+C and Transy detecting the change. Combined with the fact that the source app itself takes ~80ms to write to the clipboard, effective latency is 80–580ms. This is perceptible but acceptable for a "copy to translate" workflow.

Maccy allows user customization of this interval via `clipboardCheckInterval` (stored in UserDefaults). Transy could do the same in Settings if needed.

### Why Not Use NSPasteboard Notifications?

macOS does **NOT** provide a notification or delegate callback when the clipboard changes. There is no `NSPasteboard.didChangeNotification`. Apple deliberately chose not to expose one — polling `changeCount` is the intended and only approach. This is confirmed by:
- The absence of any notification in Apple's NSPasteboard documentation
- Every clipboard manager app (Maccy, Clipy, Flycut, CopyClip) using timer-based polling
- Apple's own sample code patterns

## Implementation Approach for Transy

### Architecture: ClipboardTrigger

A new `ClipboardTrigger` class that sits alongside (not replaces) `HotkeyMonitor`:

```swift
@MainActor
final class ClipboardTrigger {
    private var lastChangeCount: Int
    private var timer: Timer?
    private var onNewText: ((String) -> Void)?

    init() {
        lastChangeCount = NSPasteboard.general.changeCount
    }

    func start(onNewText: @escaping (String) -> Void) {
        self.onNewText = onNewText
        lastChangeCount = NSPasteboard.general.changeCount
        timer = Timer.scheduledTimer(
            timeInterval: 0.5,
            target: self,
            selector: #selector(poll),
            userInfo: nil,
            repeats: true
        )
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        onNewText = nil
    }

    @objc private func poll() {
        let current = NSPasteboard.general.changeCount
        guard current != lastChangeCount else { return }
        lastChangeCount = current

        guard let text = NSPasteboard.general.string(forType: .string),
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        onNewText?(text)
    }
}
```

### Key Difference from Current Approach: No Clipboard Restore

The current `HotkeyMonitor` + `ClipboardRestoreSession` flow:
1. Intercept first Cmd+C → snapshot clipboard ("AAA")
2. Detect second Cmd+C → read new clipboard ("BBB" = selected text)
3. Translate "BBB"
4. After popup closes → restore clipboard to "AAA"

With clipboard monitoring, the flow is simpler:
1. User copies text normally (single Cmd+C)
2. Timer detects changeCount changed
3. Read clipboard text → translate it
4. **No restore needed** — the user intentionally copied this text

This means:
- `ClipboardRestoreSession` is unnecessary for this trigger mode
- The 80ms delay for source app write is also unnecessary (the timer polls _after_ the write)
- The user's clipboard contains exactly what they expect (the copied text)

### Edge Cases

**1. Non-text clipboard content:**
If the user copies an image, file, or other non-string data, `NSPasteboard.general.string(forType: .string)` returns `nil`. The trigger simply ignores it. No action needed.

**2. Rapid successive copies:**
If the user copies 3 items within 0.5s, the timer may only catch the last one (the one present when the timer fires). For Transy, this is fine — the user wants the _last_ copied text translated.

**3. Concealed/password clipboard entries:**
Password managers (1Password, macOS Keychain) mark clipboard entries with `org.nspasteboard.ConcealedType`. Transy should check for this and skip:

```swift
let pb = NSPasteboard.general
if pb.types?.contains(NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType")) == true {
    return // Don't translate passwords
}
```

**4. Transient clipboard entries:**
Some apps mark clipboard content as `org.nspasteboard.TransientType` (meaning it should be ignored by clipboard managers). Transy should respect this convention:

```swift
if pb.types?.contains(NSPasteboard.PasteboardType("org.nspasteboard.TransientType")) == true {
    return
}
```

**5. Self-triggered changes:**
If Transy itself writes to the clipboard (e.g., "Copy Translation" button in popup), the polling timer would detect that as a new clipboard change and potentially re-trigger translation. Mitigation:

```swift
// Set a flag before writing
private var ignoringNextChange = false

func copyTranslationToClipboard(_ text: String) {
    ignoringNextChange = true
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(text, forType: .string)
}

@objc private func poll() {
    let current = NSPasteboard.general.changeCount
    guard current != lastChangeCount else { return }
    lastChangeCount = current

    if ignoringNextChange {
        ignoringNextChange = false
        return
    }
    // ... normal handling
}
```

**6. Universal Clipboard (Handoff):**
When the user copies on iPhone, it appears on Mac via Universal Clipboard. This also changes `changeCount`. The clipboard will contain an `com.apple.is-remote-clipboard` type. Transy could optionally translate these or filter them out.

## Pros and Cons

### Clipboard Monitoring (Proposed)

| Aspect | Assessment |
|--------|------------|
| ✅ **No Accessibility permission** | Eliminates the biggest UX friction point (permission dialog, System Settings walkthrough) |
| ✅ **No sandbox restrictions** | `NSPasteboard.general` is accessible from sandboxed apps too |
| ✅ **Simpler trigger flow** | No double-press detection, no clipboard save/restore |
| ✅ **No CGEvent tap** | No risk of event tap being disabled by the system |
| ✅ **Works with any copy method** | Menu Edit→Copy, right-click Copy, Cmd+C, programmatic — all detected |
| ❌ **Triggers on EVERY copy** | Can't distinguish "translate this" from "just copying normally" |
| ❌ **Polling delay** | 80–580ms latency vs near-instant with event tap |
| ❌ **No opt-in gesture** | User must explicitly have this mode on, or every copy triggers a popup |
| ❌ **Battery cost** | Timer running continuously (though negligible at 0.5s) |
| ❌ **Can't capture without clipboard change** | Can't translate selected text without the user copying it |

### CGEvent Tap / Double Cmd+C (Current)

| Aspect | Assessment |
|--------|------------|
| ✅ **Explicit intent** | Double Cmd+C is a deliberate "translate this" gesture |
| ✅ **No false positives** | Normal single copies don't trigger translation |
| ✅ **Instant detection** | Event tap fires on keyDown, no polling delay |
| ❌ **Requires Accessibility** | Permission prompt, System Settings navigation, user confusion |
| ❌ **Fragile permission** | Can be revoked, system can kill event taps |
| ❌ **Complex clipboard management** | Save/restore dance, 80ms delay, edge cases |
| ❌ **Double-press timing** | Some users press too slow or too fast |

## Can Both Approaches Coexist?

**Yes, and this is the recommended approach.** A user-selectable trigger mode in Settings:

```
Trigger Mode:
  ○ Double ⌘C (requires Accessibility permission)
  ○ Clipboard monitoring (translate on every copy)
```

Implementation strategy:
1. Add a `TriggerMode` enum to `SettingsStore` (`.doubleCmdC` / `.clipboardMonitoring`)
2. `AppDelegate` starts only the selected trigger
3. When switching modes, stop the old trigger and start the new one
4. The Accessibility permission flow (`GuidanceWindowController`) only shows for `.doubleCmdC` mode
5. Clipboard monitoring mode skips the `ClipboardRestoreSession` entirely

### Hybrid Variation: Clipboard Monitor + Quick Dismiss

A middle-ground UX: clipboard monitoring triggers a _subtle_ notification/badge instead of the full popup, and the user can click to see the full translation. This reduces the "every copy triggers a popup" annoyance while still requiring no Accessibility permission. However, this adds significant UI complexity and should be deferred.

## Privacy and Sandboxing Concerns

### Non-Sandboxed App (Current Transy Config)

Transy currently runs with `ENABLE_APP_SANDBOX: NO`. Reading `NSPasteboard.general` in a non-sandboxed app has **no restrictions**. No entitlements needed.

### Sandboxed App (If Transy Ever Sandboxes)

Even in a sandboxed app, `NSPasteboard.general` is fully accessible — it's considered a standard IPC mechanism. The App Sandbox does NOT restrict clipboard read/write. This is documented by Apple.

### Privacy Considerations

**macOS 14 Sonoma introduced a clipboard privacy prompt** (TCC) for certain scenarios. However, this applies to:
- Programmatic paste (CGEvent-based paste simulation) in some contexts
- NOT to reading `NSPasteboard.general` via polling

Reading `NSPasteboard.general.changeCount` and `.string(forType:)` does **not** trigger any TCC prompt. Clipboard managers (Maccy, etc.) continue to work on macOS 14/15 without additional permissions. **Confidence: HIGH** — verified by Maccy continuing to ship without any new permissions on Sonoma/Sequoia.

### Concealed Content

As noted in edge cases, always check for `org.nspasteboard.ConcealedType` to avoid reading password manager content. This is a community convention (see [nspasteboard.org](http://nspasteboard.org)) respected by all major clipboard managers.

## How Clipboard Manager Apps Handle This

### Maccy (Open Source, Verified)
- **Timer interval:** 0.5s default, user-configurable via `clipboardCheckInterval`
- **Detection:** `changeCount` comparison, exact pattern shown above
- **Ignored types:** `org.nspasteboard.AutoGeneratedType`, `org.nspasteboard.ConcealedType`, `org.nspasteboard.TransientType`
- **Supported types:** `.string`, `.html`, `.rtf`, `.png`, `.tiff`, `.fileURL`
- **Self-ignore:** Uses a custom pasteboard type `org.p0deje.Maccy` to mark self-originated copies
- **Source tracking:** Records `NSWorkspace.shared.frontmostApplication` as source app

### Paste (Commercial)
- Commercial app, closed source
- Uses the same `changeCount` polling pattern (standard across all macOS clipboard managers)
- Supports rich content types (images, files, links)

### CopyClip / Clipy / Flycut
- All use the identical `Timer` + `changeCount` pattern
- This is the universal approach on macOS — there is literally no alternative

## Recommendation

**Implement clipboard monitoring as a second trigger mode, user-selectable in Settings.**

### Why Both Modes:
1. **Clipboard monitoring** as the new default for users who don't want to grant Accessibility permission — simplifies onboarding dramatically
2. **Double Cmd+C** remains available for users who prefer an explicit trigger gesture and don't mind the permission

### Implementation Priority:
1. Add `ClipboardTrigger` class (straightforward, ~50 lines)
2. Add `TriggerMode` to `SettingsStore`
3. Wire up mode switching in `AppDelegate`
4. Handle edge cases (concealed types, self-triggered changes)
5. Conditionally show/hide Accessibility permission flow based on mode

### Default Mode:
Start with **clipboard monitoring as default** — it has zero friction onboarding (no permissions needed). Users who find "every copy triggers translation" annoying can switch to double Cmd+C mode.

Alternatively, offer a first-launch choice: "How would you like to trigger translations?" with explanations of both modes.

## References

- **Apple NSPasteboard docs:** [developer.apple.com/documentation/appkit/nspasteboard](https://developer.apple.com/documentation/appkit/nspasteboard)
- **Maccy source code:** [github.com/p0deje/Maccy/blob/master/Maccy/Clipboard.swift](https://github.com/p0deje/Maccy/blob/master/Maccy/Clipboard.swift) — verified, primary reference for implementation patterns
- **nspasteboard.org:** Community convention for special pasteboard types (ConcealedType, TransientType, AutoGeneratedType)
- **Maccy default interval:** `clipboardCheckInterval = 0.5` in [Defaults.Keys+Names.swift](https://github.com/p0deje/Maccy/blob/master/Maccy/Extensions/Defaults.Keys%2BNames.swift)

# Phase 12: Clipboard Monitoring - Research

**Researched:** 2026-03-31
**Domain:** macOS NSPasteboard polling, App Nap prevention, clipboard content filtering
**Confidence:** HIGH

## Summary

This phase replaces the existing Double ⌘C (Accessibility-permission-based) trigger with a permission-free clipboard monitoring system. The core mechanism polls `NSPasteboard.general.changeCount` every 500ms using `Timer.scheduledTimer`. When a new changeCount is detected, the monitor reads the pasteboard text and feeds it into the existing `TranslationCoordinator` pipeline. This is a **breaking change** — all Accessibility permission code (HotkeyMonitor, DoublePressDetector, GuidanceView, GuidanceWindowController) and their tests are deleted.

The macOS pasteboard API is simple and well-understood. `changeCount` is an integer that increments on every `clearContents()` call — it is the canonical detection mechanism for clipboard changes. Password managers (1Password, Bitwarden, etc.) use the `org.nspasteboard.ConcealedType` pasteboard type marker, and transient content uses `org.nspasteboard.TransientType`. Both are detectable by checking `NSPasteboard.general.types`. App Nap prevention via `ProcessInfo.processInfo.beginActivity` is essential for a menu bar app that must poll reliably in the background.

**Primary recommendation:** Create a new `ClipboardMonitor` class that owns the polling timer, changeCount tracking, content filtering (concealed/transient/duplicate/self-write), and calls a closure with validated text. Integrate it into `AppDelegate` as a drop-in replacement for `HotkeyMonitor`.

<user_constraints>

## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Poll NSPasteboard.general.changeCount every 500ms using Timer.scheduledTimer (RunLoop-based)
- **D-02:** Disable App Nap via NSProcessInfo.processInfo.beginActivity only while clipboard monitoring is active
- **D-03:** Clipboard monitoring is enabled by default on app launch — no user action required
- **D-04:** Double ⌘C trigger mode is **removed entirely** — clipboard monitoring is the only trigger mode
- **D-05:** Accessibility permission is no longer required — remove all AXIsProcessTrusted checks and guidance UI
- **D-06:** Remove HotkeyMonitor, DoublePressDetector, GuidanceView, GuidanceWindowController, and related AX permission code
- **D-07:** Remove corresponding tests (DoublePressDetectorTests)
- **D-08:** Only trigger translation when .string type is present AND no concealed pasteboard types exist (password manager protection)
- **D-09:** No minimum text length — even 1 character triggers translation
- **D-10:** Skip re-translation if the clipboard text is identical to the previous trigger text (duplicate suppression)
- **D-11:** After Transy writes to the clipboard (restore), record the resulting changeCount. When the polling timer fires and changeCount matches the recorded value, skip processing.

### Agent's Discretion
- Timer lifecycle management (start/stop with app lifecycle)
- Exact implementation of concealed type detection
- How to integrate with existing ClipboardManager and translation pipeline

### Deferred Ideas (OUT OF SCOPE)
- None — discussion stayed within phase scope
- "Add translation model install guidance" — belongs to Phase 13
- "Track translation cancellation latency" — separate concern

</user_constraints>

<phase_requirements>

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CLB-01 | Clipboard monitoring detects new text via NSPasteboard.general.changeCount polling | changeCount polling pattern verified — increments on `clearContents()`, reliable detection. Timer.scheduledTimer with 500ms interval and App Nap prevention confirmed working. |
| CLB-02 | User can select trigger mode in Settings (clipboard monitoring vs double ⌘C) | **SUPERSEDED by D-04**: Double ⌘C is removed entirely. No settings UI for trigger mode needed. CLB-02 is satisfied by the fact that clipboard monitoring is the sole, always-on trigger mode. |
| CLB-03 | Clipboard monitoring skips concealed and transient pasteboard types | `org.nspasteboard.ConcealedType` and `org.nspasteboard.TransientType` pasteboard type markers verified. Detection via `pb.types?.contains()` confirmed working. |
| CLB-04 | Self-originated clipboard changes are ignored to prevent re-trigger loops | Self-write prevention via changeCount tracking verified. After `ClipboardManager.restore()`, recording `pb.changeCount` and comparing on next poll correctly skips self-originated changes. |

</phase_requirements>

## Project Constraints (from copilot-instructions.md)

- Development rules live in `.github/DEVELOPMENT.md` — follow that file
- Git: Never push directly to `main`, use feature branches `phase/{phase}-{slug}`
- Commits: Conventional Commits format, include `Co-authored-by` trailer
- Use `git -c commit.gpgsign=false commit` when automated GPG signing unavailable
- Chat/conversation: Japanese; Code, commits, PRs, Issues: English
- `project.yml` managed by xcodegen is the single source of truth for `Transy.xcodeproj`

## Architecture Patterns

### Recommended Project Structure

```
Transy/
├── Trigger/
│   ├── ClipboardMonitor.swift     # NEW — polling timer + changeCount detection
│   ├── ClipboardManager.swift     # MODIFIED — add changeCount return from restore()
│   └── ClipboardRestoreSession.swift  # EVALUATE — may be simplified or removed
├── AppDelegate.swift              # MODIFIED — replace HotkeyMonitor with ClipboardMonitor
├── Settings/
│   ├── GeneralSettingsView.swift  # MODIFIED — remove trigger mode picker (if any)
│   └── SettingsStore.swift        # UNCHANGED (no trigger mode setting needed)
```

**Files to DELETE:**
```
Transy/Trigger/HotkeyMonitor.swift
Transy/Trigger/DoublePressDetector.swift
Transy/Permissions/GuidanceView.swift
Transy/Permissions/GuidanceWindowController.swift
TransyTests/DoublePressDetectorTests.swift
TransyTests/HotkeyMonitorTests.swift
```

### Pattern 1: ClipboardMonitor — Polling Timer with changeCount Detection

**What:** A `@MainActor` class that owns a `Timer.scheduledTimer` polling `NSPasteboard.general.changeCount` every 500ms. When a new changeCount is detected, it applies content filters and calls a closure with the validated text.

**When to use:** This is the sole trigger mechanism.

**Example:**
```swift
// Source: Verified against NSPasteboard and Timer APIs on macOS 15
@MainActor
final class ClipboardMonitor {
    private var timer: Timer?
    private var appNapActivity: NSObjectProtocol?
    private var lastChangeCount: Int = NSPasteboard.general.changeCount
    private var lastProcessedText: String?
    private var onNewText: ((String) -> Void)?

    func start(onNewText: @escaping (String) -> Void) {
        self.onNewText = onNewText
        // Snapshot current changeCount so we don't trigger on pre-existing clipboard
        lastChangeCount = NSPasteboard.general.changeCount

        // Prevent App Nap from throttling our timer
        appNapActivity = ProcessInfo.processInfo.beginActivity(
            options: .userInitiatedAllowingIdleSystemSleep,
            reason: "Clipboard monitoring requires timely timer execution"
        )

        timer = Timer.scheduledTimer(
            withTimeInterval: 0.5,
            repeats: true
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.poll()
            }
        }
        timer?.tolerance = 0.1 // 20% tolerance for energy efficiency
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        if let activity = appNapActivity {
            ProcessInfo.processInfo.endActivity(activity)
            appNapActivity = nil
        }
        onNewText = nil
    }

    /// Call after Transy writes to the clipboard to prevent self-triggering.
    func recordSelfWrite() {
        lastChangeCount = NSPasteboard.general.changeCount
    }

    private func poll() {
        let pb = NSPasteboard.general
        let currentCount = pb.changeCount
        guard currentCount != lastChangeCount else { return }
        lastChangeCount = currentCount

        // Filter: must have .string type
        guard let types = pb.types, types.contains(.string) else { return }

        // Filter: skip concealed (password managers) and transient content
        let concealedType = NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType")
        let transientType = NSPasteboard.PasteboardType("org.nspasteboard.TransientType")
        if types.contains(concealedType) || types.contains(transientType) { return }

        // Read text
        guard let text = pb.string(forType: .string) else { return }

        // Duplicate suppression (D-10)
        guard text != lastProcessedText else { return }
        lastProcessedText = text

        onNewText?(text)
    }
}
```

### Pattern 2: Self-Write Prevention via changeCount Tracking

**What:** After `ClipboardManager.restore()` writes to the pasteboard, call `clipboardMonitor.recordSelfWrite()` so the next poll sees a matching changeCount and skips.

**Verified behavior (tested):**
- `clearContents()` increments `changeCount` by exactly 1
- Subsequent `setString()` or `writeObjects()` on the same cleared pasteboard does NOT increment again
- Recording `pb.changeCount` immediately after any self-write and comparing on next poll reliably prevents re-triggering

**Example:**
```swift
// In AppDelegate, after restoring clipboard:
private func restoreClipboardIfNeeded() {
    guard !appState.isPopupVisible,
          let restoreSnapshot = restoreSession.consumeRestoreSnapshot() else { return }
    clipboardManager.restore(restoreSnapshot)
    clipboardMonitor.recordSelfWrite()  // Prevent re-trigger
}
```

### Pattern 3: App Nap Prevention

**What:** Menu bar apps (LSUIElement) are aggressively App Napped by macOS, which throttles timers to fire once per ~minutes instead of every 500ms. `ProcessInfo.processInfo.beginActivity` prevents this.

**API choice:**
- `.userInitiatedAllowingIdleSystemSleep` — prevents App Nap and timer throttling but allows the system to sleep when idle (D-02 compatible, energy-conscious)
- `.userInitiated` — also prevents system sleep (too aggressive for clipboard monitoring)
- `.background` — does NOT prevent App Nap (insufficient)

**Lifecycle:** Begin activity in `start()`, end in `stop()`. Per D-02, only active while monitoring is active (which per D-03 is effectively always after launch, but the API boundary is clean).

### Pattern 4: Refactored AppDelegate (No Accessibility Permission)

**What:** `applicationDidFinishLaunching` starts `ClipboardMonitor` directly — no `AXIsProcessTrusted()` check, no `GuidanceWindowController`, no `startMonitoringIfNeeded()` gating.

**Example:**
```swift
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let settingsStore = SettingsStore()
    private let appState = AppState()
    private let clipboardMonitor = ClipboardMonitor()
    private let popupController = PopupController()
    private let clipboardManager = ClipboardManager()
    private let translationCoordinator = TranslationCoordinator()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        clipboardMonitor.start { [weak self] text in
            self?.handleTrigger(text: text)
        }
    }

    private func handleTrigger(text: String) {
        let normalizedText = normalizedSourceText(text)
        guard !normalizedText.isEmpty else { return }

        _ = translationCoordinator.begin(sourceText: normalizedText)
        appState.isPopupVisible = true

        let frozenTarget = settingsStore.snapshotTargetLanguage()
        let availabilityClient = TranslationAvailabilityClient(targetLanguage: frozenTarget)

        popupController.show(
            translationCoordinator: translationCoordinator,
            availabilityClient: availabilityClient,
            settingsStore: settingsStore
        ) { [weak self] in
            guard let self else { return }
            self.translationCoordinator.dismiss()
            self.appState.isPopupVisible = false
            self.restoreClipboardIfNeeded()
        }
    }

    private func restoreClipboardIfNeeded() {
        // No restore needed — clipboard monitoring doesn't capture pre-state
        // The user's copy action is the trigger; the clipboard already has
        // the text they expect.
    }
}
```

### Pattern 5: ClipboardRestoreSession Simplification

**What:** With clipboard monitoring, there is no "pre-capture snapshot" concept. The user explicitly copies text (Cmd+C), which writes to the clipboard, and the monitor detects the change. There's no need to restore the clipboard to a pre-trigger state because the trigger IS the user's intentional copy action.

**Decision:** `ClipboardRestoreSession` can be **removed** along with the restore logic in `AppDelegate`. The `ClipboardManager.saveCurrentContents()` and `restore()` methods become unnecessary for the trigger flow.

**However:** `ClipboardManager` should be retained as it may be useful in future for other clipboard operations, and its `readSelectedText()` pattern could be extracted or reused.

### Anti-Patterns to Avoid

- **DispatchSourceTimer for polling:** Decision D-01 locked Timer.scheduledTimer. GCD timers add complexity without benefit for 500ms polling — RunLoop-based timers fire naturally on main thread with @MainActor compatibility.
- **Polling without App Nap prevention:** Timer will be throttled to minutes in menu bar apps. MUST use `beginActivity`.
- **Checking `changeCount > lastChangeCount` instead of `!=`:** `changeCount` can wrap around (it's an `Int`, but the comparison should use `!=` not `>` to be safe with counter overflow).
- **Reading pasteboard types and string in separate poll cycles:** Always read types and string in the same poll — the pasteboard can change between calls.
- **Forgetting to update `lastChangeCount` on non-string changes:** If the clipboard changes to an image (no .string type), we must still update `lastChangeCount` so we don't keep re-checking the same change.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Clipboard change detection | NSDistributedNotificationCenter observation | `NSPasteboard.general.changeCount` polling | macOS has no reliable clipboard-change notification — `changeCount` polling is the standard pattern used by all clipboard managers |
| App Nap prevention | Custom keep-alive timer tricks | `ProcessInfo.processInfo.beginActivity` | Apple's official API, clean lifecycle, documented behavior |
| Password detection | Heuristic text analysis (length, entropy) | `org.nspasteboard.ConcealedType` pasteboard type | Industry standard (1Password, Bitwarden, KeePassXC all set this type); heuristics have false positives |
| Transient content detection | Timeout-based clipboard clearing | `org.nspasteboard.TransientType` pasteboard type | nspasteboard.org spec, set by apps that write temporary data |

**Key insight:** macOS deliberately does NOT provide a clipboard change notification API. The `changeCount` polling pattern is not a workaround — it is the intended and universally used approach. Every clipboard manager on macOS (Maccy, CopyClip, Paste, Alfred) uses this exact pattern.

## Common Pitfalls

### Pitfall 1: App Nap Throttling the Poll Timer

**What goes wrong:** Timer fires once every 30-60 seconds instead of every 500ms, making clipboard monitoring feel broken.
**Why it happens:** macOS App Nap aggressively throttles timers for background/accessory apps (LSUIElement = true).
**How to avoid:** Call `ProcessInfo.processInfo.beginActivity(options: .userInitiatedAllowingIdleSystemSleep, ...)` before starting the timer.
**Warning signs:** Clipboard detection works immediately after launch but becomes sluggish after a few minutes.

### Pitfall 2: Self-Trigger Loop

**What goes wrong:** Transy restores clipboard → changeCount bumps → monitor detects change → triggers translation again → infinite loop.
**Why it happens:** `ClipboardManager.restore()` calls `clearContents()` which increments `changeCount`.
**How to avoid:** After every self-write to the clipboard, update `lastChangeCount = NSPasteboard.general.changeCount` (the `recordSelfWrite()` pattern).
**Warning signs:** Translation popup immediately re-appears after dismissal.

### Pitfall 3: Triggering on Launch with Pre-existing Clipboard

**What goes wrong:** App launches and immediately triggers translation on whatever text was already on the clipboard.
**Why it happens:** `lastChangeCount` initialized to 0 instead of `NSPasteboard.general.changeCount`.
**How to avoid:** Initialize `lastChangeCount` to `NSPasteboard.general.changeCount` in `start()` (not `init()`), so the current clipboard state is treated as "already seen."
**Warning signs:** Every app launch shows a translation popup.

### Pitfall 4: Missing changeCount Update on Non-Text Changes

**What goes wrong:** User copies an image → monitor sees new changeCount, finds no .string type, skips. But doesn't update `lastChangeCount`. Next poll re-checks the same changeCount forever (wasted cycles).
**Why it happens:** Early return before updating `lastChangeCount` when content isn't text.
**How to avoid:** Update `lastChangeCount` immediately after detecting a new count, BEFORE checking content types.
**Warning signs:** No visible bug, but unnecessary repeated pasteboard reads on every poll.

### Pitfall 5: Timer Retain Cycle

**What goes wrong:** Timer holds strong reference to closure, closure captures `self` strongly → `ClipboardMonitor` never deallocates, timer fires forever.
**Why it happens:** `Timer.scheduledTimer(withTimeInterval:repeats:block:)` retains the block strongly.
**How to avoid:** Use `[weak self]` in the timer closure. Invalidate the timer in `stop()`.
**Warning signs:** Memory leak, timer continues firing after expected teardown.

### Pitfall 6: Concurrent Pasteboard Access

**What goes wrong:** Reading `types` and `string(forType:)` in separate statements — pasteboard can change between them.
**Why it happens:** Another app writes to the clipboard between our `types` check and `string` read.
**How to avoid:** Accept that this is a benign race condition. If `string(forType:)` returns nil after `types` contained `.string`, just skip. The next poll will pick up the new state. All access is on `@MainActor` (single-threaded), but external apps can modify the pasteboard at any time.
**Warning signs:** Rare nil returns from `string(forType:)` after confirming `.string` in types.

## Code Examples

### Complete ClipboardMonitor with All Filters

```swift
// Source: Verified against macOS 15 NSPasteboard, Timer, ProcessInfo APIs
import AppKit

@MainActor
final class ClipboardMonitor {
    private var timer: Timer?
    private var appNapActivity: NSObjectProtocol?
    private var lastChangeCount: Int = 0
    private var lastProcessedText: String?
    private var onNewText: ((String) -> Void)?

    private static let concealedType = NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType")
    private static let transientType = NSPasteboard.PasteboardType("org.nspasteboard.TransientType")

    func start(onNewText: @escaping (String) -> Void) {
        self.onNewText = onNewText
        lastChangeCount = NSPasteboard.general.changeCount
        lastProcessedText = nil

        appNapActivity = ProcessInfo.processInfo.beginActivity(
            options: .userInitiatedAllowingIdleSystemSleep,
            reason: "Clipboard monitoring requires timely timer execution"
        )

        timer = Timer.scheduledTimer(
            withTimeInterval: 0.5,
            repeats: true
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.poll()
            }
        }
        timer?.tolerance = 0.1
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        if let activity = appNapActivity {
            ProcessInfo.processInfo.endActivity(activity)
            appNapActivity = nil
        }
        lastProcessedText = nil
        onNewText = nil
    }

    /// Record a self-originated clipboard write to prevent re-triggering.
    func recordSelfWrite() {
        lastChangeCount = NSPasteboard.general.changeCount
    }

    private func poll() {
        let pb = NSPasteboard.general
        let currentCount = pb.changeCount

        // No change since last poll
        guard currentCount != lastChangeCount else { return }
        lastChangeCount = currentCount

        // Must have types and include .string
        guard let types = pb.types, types.contains(.string) else { return }

        // Skip concealed (password managers) and transient content
        guard !types.contains(Self.concealedType),
              !types.contains(Self.transientType) else { return }

        // Read text
        guard let text = pb.string(forType: .string) else { return }

        // Duplicate suppression
        guard text != lastProcessedText else { return }
        lastProcessedText = text

        onNewText?(text)
    }
}
```

### Refactored AppDelegate Integration

```swift
// Source: Based on existing AppDelegate.swift patterns
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let appState = AppState()
    let settingsStore = SettingsStore()
    private let clipboardMonitor = ClipboardMonitor()
    private let popupController = PopupController()
    private let translationCoordinator = TranslationCoordinator()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        clipboardMonitor.start { [weak self] text in
            self?.handleTrigger(text: text)
        }
    }

    private func handleTrigger(text: String) {
        let normalizedText = normalizedSourceText(text)
        guard !normalizedText.isEmpty else { return }

        _ = translationCoordinator.begin(sourceText: normalizedText)
        appState.isPopupVisible = true

        let frozenTarget = settingsStore.snapshotTargetLanguage()
        let availabilityClient = TranslationAvailabilityClient(targetLanguage: frozenTarget)

        popupController.show(
            translationCoordinator: translationCoordinator,
            availabilityClient: availabilityClient,
            settingsStore: settingsStore
        ) { [weak self] in
            guard let self else { return }
            self.translationCoordinator.dismiss()
            self.appState.isPopupVisible = false
        }
    }
}
```

### Concealed Type Constants

```swift
// Source: nspasteboard.org convention, verified against 1Password/Bitwarden behavior
extension NSPasteboard.PasteboardType {
    /// Set by password managers (1Password, Bitwarden, KeePassXC) to mark sensitive entries.
    static let concealed = NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType")

    /// Set by apps writing temporary clipboard data that should not be persisted.
    static let transient = NSPasteboard.PasteboardType("org.nspasteboard.TransientType")

    /// Set by apps writing auto-generated content (e.g., OTP codes).
    static let autoGenerated = NSPasteboard.PasteboardType("org.nspasteboard.AutoGeneratedType")
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Double ⌘C via Accessibility permission | Clipboard monitoring (changeCount polling) | Phase 12 (this phase) | No permissions required, simpler UX |
| `NSEvent.addGlobalMonitorForEvents` + AXIsProcessTrusted | `Timer.scheduledTimer` + `NSPasteboard.general.changeCount` | Phase 12 | Removes Accessibility permission requirement entirely |
| Pre-capture clipboard snapshot + restore | Direct detection of user's copy action | Phase 12 | ClipboardRestoreSession pattern likely no longer needed |

**Deprecated/removed:**
- `HotkeyMonitor` / `DoublePressDetector`: Replaced by `ClipboardMonitor`
- `GuidanceView` / `GuidanceWindowController`: No longer needed (no AX permission required)
- `AXIsProcessTrusted()` calls: Removed from entire codebase
- `ApplicationServices` import in AppDelegate: No longer needed (was only for AXIsProcessTrusted)

## Open Questions

1. **ClipboardRestoreSession removal**
   - What we know: With clipboard monitoring, the user's copy action IS the trigger. There's no "pre-state" to restore because the user intentionally copied text.
   - What's unclear: Whether any edge case in the popup dismiss flow still needs clipboard restoration.
   - Recommendation: Remove `ClipboardRestoreSession` and `restoreSession` from `AppDelegate`. Remove `ClipboardManager.saveCurrentContents()` and `restore()` if no other consumers exist. If uncertain, keep `ClipboardManager` intact but remove `ClipboardRestoreSession`.

2. **CLB-02 requirement vs D-04 decision**
   - What we know: CLB-02 says "User can select trigger mode in Settings" but D-04 removes the Double ⌘C mode entirely.
   - What's unclear: Whether REQUIREMENTS.md should be updated to reflect that CLB-02 is satisfied differently.
   - Recommendation: CLB-02 is satisfied by clipboard monitoring being the sole, always-on mode. The planner should update REQUIREMENTS.md to note this when marking CLB-02 complete.

3. **HotkeyMonitorTests vs ClipboardManagerTests**
   - What we know: HotkeyMonitorTests and DoublePressDetectorTests must be deleted. ClipboardManagerTests test save/restore which may no longer be needed.
   - What's unclear: Whether ClipboardManagerTests should be kept, modified, or deleted.
   - Recommendation: Delete ClipboardManagerTests if `saveCurrentContents()` and `restore()` are removed. If `ClipboardManager` is kept, keep tests for any surviving methods.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Swift Testing (built-in, Xcode 16+) |
| Config file | Xcode project target `TransyTests` (in project.yml) |
| Quick run command | `xcodebuild test -scheme Transy -destination 'platform=macOS' -only-testing:TransyTests 2>&1 \| tail -20` |
| Full suite command | `xcodebuild test -scheme Transy -destination 'platform=macOS' 2>&1 \| tail -40` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CLB-01 | changeCount polling detects new text | unit | `xcodebuild test -scheme Transy -only-testing:TransyTests/ClipboardMonitorTests` | ❌ Wave 0 |
| CLB-02 | Clipboard monitoring is sole trigger (no mode picker) | manual | Verify no trigger mode UI in GeneralSettingsView | N/A |
| CLB-03 | Concealed/transient types are skipped | unit | `xcodebuild test -scheme Transy -only-testing:TransyTests/ClipboardMonitorTests` | ❌ Wave 0 |
| CLB-04 | Self-originated writes are ignored | unit | `xcodebuild test -scheme Transy -only-testing:TransyTests/ClipboardMonitorTests` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `xcodebuild build -scheme Transy -destination 'platform=macOS'` (compile check)
- **Per wave merge:** `xcodebuild test -scheme Transy -destination 'platform=macOS'`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `TransyTests/ClipboardMonitorTests.swift` — covers CLB-01, CLB-03, CLB-04 (test poll logic, concealed skip, self-write skip, duplicate suppression)
- [ ] Delete `TransyTests/DoublePressDetectorTests.swift` — removed with DoublePressDetector
- [ ] Delete `TransyTests/HotkeyMonitorTests.swift` — removed with HotkeyMonitor
- [ ] Evaluate `TransyTests/ClipboardManagerTests.swift` — keep or modify based on ClipboardManager changes
- [ ] Evaluate `TransyTests/ClipboardRestoreSessionTests.swift` — remove if ClipboardRestoreSession is deleted

### Testing Strategy for ClipboardMonitor

The `poll()` method is private but its logic can be tested by extracting the filtering logic or by testing through the public API:

**Option A (Recommended): Extract filter logic into a testable pure function:**
```swift
struct ClipboardContent {
    let changeCount: Int
    let types: [NSPasteboard.PasteboardType]
    let text: String?
}

enum ClipboardFilterResult {
    case skip       // No change, concealed, transient, duplicate, or no string
    case trigger(String)  // Valid new text to translate
}

// Pure function — easily testable
func filterClipboardContent(
    _ content: ClipboardContent,
    lastChangeCount: Int,
    lastProcessedText: String?
) -> ClipboardFilterResult { ... }
```

**Option B: Test via public `start()`/`recordSelfWrite()` by writing to NSPasteboard in tests:**
```swift
@Test("detects new clipboard text")
@MainActor
func detectsNewText() async {
    var receivedText: String?
    let monitor = ClipboardMonitor()
    monitor.start { text in receivedText = text }

    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString("test", forType: .string)

    // Wait for timer to fire
    try? await Task.sleep(for: .milliseconds(600))

    #expect(receivedText == "test")
    monitor.stop()
}
```

## Sources

### Primary (HIGH confidence)
- **NSPasteboard API** — verified via direct Swift execution on macOS 15 (changeCount behavior, types, PasteboardType constants)
- **Timer API** — verified via direct Swift execution (scheduledTimer, tolerance, invalidation)
- **ProcessInfo.processInfo.beginActivity** — verified via direct Swift execution (activity options, lifecycle)
- **Existing codebase** — full read of Trigger/, Permissions/, Settings/, AppDelegate.swift, all test files

### Secondary (MEDIUM confidence)
- **nspasteboard.org convention** — `org.nspasteboard.ConcealedType`, `TransientType`, `AutoGeneratedType` are community conventions adopted by major password managers (1Password, Bitwarden, KeePassXC). Not an Apple API but universally used.

### Tertiary (LOW confidence)
- None — all critical claims verified via direct API testing

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all APIs verified via direct execution on the target platform
- Architecture: HIGH — patterns follow existing codebase conventions (@MainActor, Observable, Timer)
- Pitfalls: HIGH — each pitfall verified by testing the actual API behavior (changeCount semantics, self-write detection, App Nap)
- Content filtering: HIGH for ConcealedType/TransientType (tested), MEDIUM for comprehensive password manager coverage (depends on each app implementing the convention)

**Research date:** 2026-03-31
**Valid until:** 2026-06-30 (stable macOS APIs, unlikely to change)

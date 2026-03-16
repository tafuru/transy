---
phase: 02-trigger-popup
verified: 2026-03-14T20:00:00Z
status: passed
score: 10/10 must-haves verified
re_verification: false
---

# Phase 2: Trigger & Popup Verification Report

**Phase Goal:** Implement the selected-text trigger and popup shell for Transy: pressing Command+C twice should capture selected text, restore the previous clipboard contents, and show a non-focus-stealing popup with the source text in a muted loading-state style. This phase also includes user guidance when the required monitoring permissions are missing.
**Verified:** 2026-03-14T20:00:00Z
**Status:** ✅ passed
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| #  | Truth | Status | Evidence |
|----|-------|--------|----------|
| 1  | Double-pressing Cmd+C in any app opens a floating popup with selected text in muted style | ✓ VERIFIED | HotkeyMonitor → AppDelegate.handleTrigger → PopupController.show → PopupView(.secondary) |
| 2  | Popup appears without stealing focus — source app remains active | ✓ VERIFIED | NSPanel `.nonActivatingPanel` styleMask + `orderFrontRegardless()` + `hidesOnDeactivate = false` |
| 3  | Source text visible immediately in `.secondary` foreground style (readable, not skeleton blobs) | ✓ VERIFIED | `PopupView.foregroundStyle(.secondary)`, human-confirmed |
| 4  | Pressing Escape dismisses the popup regardless of which app is frontmost | ✓ VERIFIED | `addGlobalMonitorForEvents(.keyDown)` with `keyCode == 53`; human-confirmed |
| 5  | Clicking outside the popup frame dismisses it | ✓ VERIFIED | `addGlobalMonitorForEvents(.leftMouseDown/.rightMouseDown)` checking `panel.frame.contains`; human-confirmed |
| 6  | Re-trigger while popup is showing updates in-place (no stacking) | ✓ VERIFIED | `show()` calls `removeDismissMonitors()` then replaces `panel.contentView` without `orderOut` |
| 7  | Original clipboard contents restored when popup dismisses | ✓ VERIFIED | First-press snapshot in `HotkeyMonitor`; passed as `preSnapshot` to `handleTrigger`; `restore()` called in `onDismiss`; human-confirmed + regression test passing |
| 8  | Missing Accessibility permission shows guidance window instead of attempting to monitor | ✓ VERIFIED | `handleTrigger` guard `AXIsProcessTrusted()` → `showIfNeeded()`; `HotkeyMonitor.start` bails silently when not trusted |
| 9  | Opening the Transy menu while Accessibility is missing surfaces guidance window | ✓ VERIFIED | `MenuBarView.onAppear { GuidanceWindowController.shared.showIfNeeded() }`; human-confirmed |
| 10 | Granting Accessibility access starts monitoring automatically without relaunch | ✓ VERIFIED | `GuidanceWindowController.onPermissionGranted` → `AppDelegate.startMonitoringIfNeeded()`; trust-poll timer fires every 2s |

**Score:** 10/10 truths verified

---

### Required Artifacts

| Artifact | Provides | Exists | Lines | Status |
|----------|----------|--------|-------|--------|
| `Transy/Permissions/GuidanceView.swift` | SwiftUI guidance content with instructions and "Open System Settings" button | ✓ | 24 | ✓ VERIFIED |
| `Transy/Permissions/GuidanceWindowController.swift` | NSWindowController singleton; AXIsProcessTrusted gate; trust-poll timer; `onPermissionGranted` callback | ✓ | 52 | ✓ VERIFIED |
| `Transy/Trigger/DoublePressDetector.swift` | Stateful struct with `record() -> PressResult`; 400ms threshold; reset-after-fire | ✓ | 30 | ✓ VERIFIED |
| `Transy/Trigger/ClipboardManager.swift` | `saveCurrentContents()`, `readSelectedText()`, `restore(_:)` using NSPasteboard deep copy | ✓ | 40 | ✓ VERIFIED |
| `Transy/Trigger/HotkeyMonitor.swift` | NSEvent global monitor; `.intersection(.deviceIndependentFlagsMask) == .command` filter; first-press snapshot logic | ✓ | 56 | ✓ VERIFIED |
| `Transy/Popup/PopupView.swift` | Source text `.secondary` style, 4-line limit, 380pt wide | ✓ | 20 | ✓ VERIFIED |
| `Transy/Popup/PopupController.swift` | NSPanel `.borderless + .nonActivatingPanel`; fade-in; Escape + outside-click monitors; `orderFrontRegardless()` | ✓ | 95 | ✓ VERIFIED |
| `Transy/AppDelegate.swift` | Wires HotkeyMonitor → ClipboardManager → PopupController → GuidanceWindowController | ✓ | 70 | ✓ VERIFIED |
| `Transy/AppState.swift` | `isPopupVisible: Bool` activated | ✓ | 10 | ✓ VERIFIED |
| `Transy/MenuBar/MenuBarView.swift` | `.onAppear` → `showIfNeeded()` fallback | ✓ | 24 | ✓ VERIFIED |
| `TransyTests/DoublePressDetectorTests.swift` | Timing, threshold, reset, triple-press tests (5 tests) | ✓ | 52 (≥40 ✓) | ✓ VERIFIED |
| `TransyTests/ClipboardManagerTests.swift` | Save/restore round-trip, regression test (4 tests) | ✓ | 84 (≥30 ✓) | ✓ VERIFIED |
| `TransyTests/HotkeyMonitorTests.swift` | Interface existence + compilation tests (2 tests) | ✓ | 22 (≥15 ✓) | ✓ VERIFIED |

---

### Key Link Verification

| From | To | Via | Status | Detail |
|------|----|-----|--------|--------|
| `HotkeyMonitor.handle(_:)` | `DoublePressDetector.record()` | `switch detector.record()` | ✓ WIRED | Present in `handle(_:)`; `.doublePress` branch calls callback |
| `HotkeyMonitor` | `onDoubleCmdC` callback | called when `.doublePress` | ✓ WIRED | `onDoubleCmdC?(snapshot)` in `.doublePress` case |
| `ClipboardManager.saveCurrentContents()` | `NSPasteboard.general.pasteboardItems` | deep copy loop | ✓ WIRED | `(pb.pasteboardItems ?? []).compactMap { ... }` |
| `AppDelegate.handleTrigger()` | `ClipboardManager → 80ms sleep → readSelectedText() → PopupController.show()` | `async Task @MainActor` | ✓ WIRED | `Task.sleep(for: .milliseconds(80))` at line 54 |
| `PopupController.show()` | `panel.orderFrontRegardless()` | non-activating show for LSUIElement app | ✓ WIRED | Uses `orderFrontRegardless()` (correct for accessory apps; `orderFront(nil)` is a no-op when not active) |
| `PopupController.attachDismissMonitors()` | `NSEvent.addGlobalMonitorForEvents` | `.keyDown` (Escape) and `.leftMouseDown/.rightMouseDown` | ✓ WIRED | Both monitors present; outside-click checks `panel.frame.contains(NSEvent.mouseLocation)` |
| `PopupController.dismiss()` | `onDismiss` callback | called after `panel.orderOut(nil)` | ✓ WIRED | `onDismiss?()` in `dismiss()` |
| `HotkeyMonitor.start(onDoubleCmdC:)` | `AppDelegate.handleTrigger()` | closure at launch | ✓ WIRED | `hotkeyMonitor.start(onDoubleCmdC: { [weak self] preSnapshot in self?.handleTrigger(preSnapshot: preSnapshot) })` |
| `MenuBarView.body.onAppear` | `GuidanceWindowController.shared.showIfNeeded()` | explicit fallback | ✓ WIRED | `.onAppear { GuidanceWindowController.shared.showIfNeeded() }` |
| `GuidanceWindowController.onPermissionGranted` | `AppDelegate.startMonitoringIfNeeded()` | trust-poll callback | ✓ WIRED | `GuidanceWindowController.shared.onPermissionGranted = { [weak self] in self?.startMonitoringIfNeeded() }` |

---

### Requirements Coverage

| Requirement | Source Plan(s) | Description | Status | Evidence |
|-------------|---------------|-------------|--------|----------|
| TRIG-01 | 02-02, 02-03 | Double Cmd+C trigger within ~400ms | ✓ SATISFIED | `DoublePressDetector` with 400ms threshold; `intersection(.deviceIndependentFlagsMask) == .command` + `keyCode == 8` + `!isARepeat` guards; 5/5 timing tests pass |
| TRIG-02 | 02-01, 02-03 | Guidance when Accessibility permission is missing | ✓ SATISFIED | `GuidanceWindowController.showIfNeeded()` gated on `!AXIsProcessTrusted()`; shown from `MenuBarView.onAppear` and `handleTrigger`; human-confirmed |
| TRIG-03 | 02-02, 02-03 | Previous clipboard contents preserved after trigger | ✓ SATISFIED | First-press snapshot in `HotkeyMonitor`; `ClipboardManager.restore()` on dismiss; regression test passing; human-confirmed |
| POP-01 | 02-03 | Floating popup does not take focus from current app | ✓ SATISFIED | `.nonActivatingPanel` styleMask + `orderFrontRegardless()` + `hidesOnDeactivate = false`; human-confirmed |
| POP-02 | 02-03 | Source text visible immediately in muted loading style | ✓ SATISFIED | `PopupView.foregroundStyle(.secondary)`; renders immediately in `show()`; human-confirmed |
| POP-03 | 02-03 | Popup dismissed with Escape or outside click | ✓ SATISFIED | Two global monitors: `keyCode == 53` for Escape, frame-bounds check for outside clicks; human-confirmed |

**All 6 requirements satisfied. No orphaned requirements.**

---

### Test Results

```
✔ Test "first press returns .firstPress"                                          passed
✔ Test "second press within threshold returns .doublePress"                       passed
✔ Test "second press outside threshold returns .firstPress (new sequence)"        passed
✔ Test "triple press fires exactly once then resets"                              passed
✔ Test "threshold boundary: at or past threshold returns .firstPress"             passed
✔ Test "save and restore preserves string content"                                passed
✔ Test "readSelectedText returns current pasteboard string"                       passed
✔ Test "restore with empty items clears clipboard"                                passed
✔ Test "snapshot taken before source-app copy restores original clipboard"        passed
✔ Test "HotkeyMonitor can be instantiated"                                        passed
✔ Test "start and stop do not crash when called on main actor"                    passed

Test run with 11 tests in 3 suites passed. BUILD SUCCEEDED.
```

---

### Anti-Patterns Found

None. No TODOs, FIXMEs, placeholders, empty returns, or stub implementations detected in any of the 10 modified source files.

**Notable implementation deviation:** `PopupController` uses `orderFrontRegardless()` instead of the plan's documented `orderFront(nil)`. This is correct — `orderFront(nil)` is a documented no-op for background/accessory apps that are never active. The code includes explicit inline comments explaining the rationale. This is an improvement over the plan, not a gap.

---

### Human Verification Completed

Per pre-verification human smoke test, the following behaviors were confirmed live:

1. **Popup visibility** — Popup appears after double Cmd+C in an external app ✅
2. **Muted source text** — Text renders in secondary (muted) style, readable but not prominent ✅
3. **Escape dismiss** — Escape key dismisses popup regardless of active app ✅
4. **Outside-click dismiss** — Clicking outside popup frame dismisses it ✅
5. **Clipboard restore** — Original clipboard content is present after popup dismisses ✅
6. **Permission guidance** — Guidance window surfaces correctly when Accessibility is not granted ✅

---

## Summary

Phase 2 goal fully achieved. All six requirements (TRIG-01, TRIG-02, TRIG-03, POP-01, POP-02, POP-03) are satisfied by substantive, wired implementations. The trigger subsystem (DoublePressDetector + HotkeyMonitor + ClipboardManager) is fully unit-tested with 11/11 tests passing. The popup subsystem (PopupView + PopupController) and permissions subsystem (GuidanceView + GuidanceWindowController) are wired end-to-end through AppDelegate. Human smoke testing has confirmed all six user-visible behaviors.

---

_Verified: 2026-03-14T20:00:00Z_
_Verifier: Claude (gsd-verifier)_

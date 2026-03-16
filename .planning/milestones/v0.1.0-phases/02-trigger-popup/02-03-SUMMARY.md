---
phase: 02-trigger-popup
plan: 03
subsystem: ui
tags: [swift, swiftui, nspanel, popup, hotkey, clipboard, accessibility]

# Dependency graph
requires:
  - phase: 02-trigger-popup/02-01
    provides: GuidanceWindowController — Accessibility permission gate and guidance UI
  - phase: 02-trigger-popup/02-02
    provides: DoublePressDetector, ClipboardManager, HotkeyMonitor — trigger and clipboard subsystems
provides:
  - PopupView — SwiftUI muted-text popup content (380pt wide, 4-line truncation, .secondary style)
  - PopupController — NSPanel .nonActivatingPanel host with fade-in, dismiss monitors, screen placement
  - AppDelegate full wiring — HotkeyMonitor → ClipboardManager → PopupController → GuidanceWindowController
  - MenuBarView explicit permission fallback — GuidanceWindowController.showIfNeeded() on menu open
  - Complete Phase 2 trigger-to-popup flow, human smoke-tested and approved
affects: [03-translation-loop]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - NSPanel .nonActivatingPanel + .borderless for focus-non-stealing popup
    - orderFrontRegardless() instead of makeKeyAndOrderFront for background-app visibility
    - hidesOnDeactivate=false to prevent panel vanishing when source app regains focus
    - NSEvent.addGlobalMonitorForEvents for Escape + outside-click dismiss (panel is not key window)
    - Clipboard snapshot at first Cmd+C (before source app writes selection) + restore on dismiss
    - GuidanceWindowController.onPermissionGranted callback for auto-start monitoring without relaunch

key-files:
  created:
    - Transy/Popup/PopupView.swift
    - Transy/Popup/PopupController.swift
  modified:
    - Transy/AppDelegate.swift
    - Transy/AppState.swift
    - Transy/MenuBar/MenuBarView.swift

key-decisions:
  - "orderFrontRegardless() used instead of orderFront(nil) so popup surfaces when Transy is a background app (LSUIElement)"
  - "Clipboard snapshot taken at first Cmd+C keyDown (before source app writes selection); restore happens in onDismiss callback"
  - "hidesOnDeactivate=false is mandatory — default true causes panel to vanish when source app regains focus"
  - "PopupView uses .secondary foreground style, not .redacted(reason: .placeholder) — readable muted text vs unreadable gray blobs"
  - "MenuBarView.onAppear calls GuidanceWindowController.showIfNeeded() as explicit permission fallback — no proactive launch prompt"

patterns-established:
  - "NSPanel setup: .borderless + .nonActivatingPanel, hidesOnDeactivate=false, orderFrontRegardless()"
  - "Global event monitors for dismiss: keyCode 53 (Escape) + left/right mouse down outside panel frame"
  - "Clipboard save/restore: snapshot in handleTrigger() before Task.sleep(80ms), restore in onDismiss closure"

requirements-completed: [TRIG-02, POP-01, POP-02, POP-03]

# Metrics
duration: ~35min (including human smoke-test checkpoint)
completed: "2026-03-14"
tasks_completed: 3
files_created: 2
files_modified: 3
---

# Phase 2 Plan 03: Popup + Wiring Summary

**NSPanel non-activating popup with SwiftUI muted text, wired to double-Cmd+C trigger with clipboard save/restore — human smoke-tested and all six Phase 2 success criteria confirmed.**

## Performance

- **Duration:** ~35 min (including human verification checkpoint)
- **Started:** 2026-03-14 (continuation of phase session)
- **Completed:** 2026-03-14T10:45:42Z
- **Tasks:** 3 (Tasks 1+2 automated, Task 3 human smoke-test)
- **Files modified:** 5 (2 created, 3 updated)

## Accomplishments

- Created `PopupView` (SwiftUI, `.secondary` muted style, 380pt, 4-line truncation) and `PopupController` (NSPanel `.nonActivatingPanel`, fade-in, Escape + outside-click dismiss monitors, top-center screen placement)
- Wired full trigger-to-popup flow in `AppDelegate`: HotkeyMonitor → 80ms delay → ClipboardManager.readSelectedText → PopupController.show → (dismiss) → ClipboardManager.restore
- Fixed two critical runtime issues found during smoke test: `orderFrontRegardless()` for LSUIElement background-app visibility, and clipboard snapshot timing for correct restore
- Human smoke test approved — all six Phase 2 success criteria verified live: popup on double-Cmd+C, no focus steal, muted text, Escape dismiss, click-outside dismiss, clipboard restore, guidance window fallback

## Task Commits

Each task was committed atomically:

1. **Task 1: PopupView.swift + PopupController.swift** — `3984677` (feat)
2. **Task 2: AppDelegate + AppState + MenuBarView wiring** — `884dc09` (feat)
3. **Fix: orderFrontRegardless() for background app visibility** — `412b96d` (fix — deviation Rule 1)
4. **Fix: Clipboard snapshot at first Cmd+C for correct restore** — `3b544ee` (fix — deviation Rule 1)
5. **Task 3: Human smoke-test approved** — no code commit (verification only)

## Files Created/Modified

- `Transy/Popup/PopupView.swift` — SwiftUI popup content: source text in `.secondary` style, 4-line truncation, 380pt wide, `.regularMaterial` background, no chrome
- `Transy/Popup/PopupController.swift` — NSPanel host: `.borderless` + `.nonActivatingPanel`, `hidesOnDeactivate=false`, `orderFrontRegardless()`, fade-in animation, global Escape + click-outside dismiss monitors, top-center screen placement using mouse-cursor screen (not NSScreen.main)
- `Transy/AppDelegate.swift` — Full Phase 2 wiring: `startMonitoringIfNeeded()`, `handleTrigger()` with 80ms Task.sleep, clipboard snapshot before delay + restore on dismiss, `GuidanceWindowController.onPermissionGranted` → `startMonitoringIfNeeded()` for post-grant auto-start
- `Transy/AppState.swift` — `isPopupVisible: Bool = false` activated (Phase 2 stub uncommented); Phase 3/4 placeholders remain as comments
- `Transy/MenuBar/MenuBarView.swift` — `.onAppear { GuidanceWindowController.shared.showIfNeeded() }` added as explicit permission fallback on menu open

## Decisions Made

1. **`orderFrontRegardless()` over `orderFront(nil)`** — Transy is an `LSUIElement` app and is never frontmost. `orderFront(nil)` silently no-ops when the app is not active; `orderFrontRegardless()` forces the panel to surface regardless of activation state. Discovered during smoke test.
2. **Clipboard snapshot at first Cmd+C (before Task.sleep)** — The 80ms delay lets the source app write the selection to the clipboard. If we snapshot after the delay, we capture the selected text and cannot distinguish "original clipboard" from "trigger content". Snapshotting at the moment of the first Cmd+C keyDown captures what was in the clipboard before the user copied anything during this trigger cycle.
3. **`.secondary` foreground, not `.redacted(reason: .placeholder)`** — User-specified: "readable muted/loading treatment". `.redacted` produces gray blobs. `.secondary` is muted but readable.
4. **`hidesOnDeactivate = false`** — Without this, NSPanel disappears the instant the source app regains focus (which happens immediately after trigger fires). Mandatory for the popup to remain visible.
5. **`MenuBarView.onAppear` as permission fallback** — No proactive guidance on first launch (user decision from Phase 2 planning). Menu open is the natural explicit action when hotkey monitoring silently fails.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `orderFront(nil)` doesn't surface popup when Transy is a background LSUIElement app**
- **Found during:** Task 2 smoke-test (popup did not appear after double-Cmd+C)
- **Issue:** `NSPanel.orderFront(nil)` is a no-op when the calling app is not the active/frontmost app. Transy runs as an `LSUIElement` agent and is never activated, so `orderFront(nil)` silently did nothing.
- **Fix:** Replaced `panel.orderFront(nil)` with `panel.orderFrontRegardless()` in `PopupController.show()`
- **Files modified:** `Transy/Popup/PopupController.swift`
- **Verification:** Popup appeared on double-Cmd+C during smoke test
- **Committed in:** `412b96d`

**2. [Rule 1 - Bug] Clipboard restore was restoring the selected text (trigger content), not the original clipboard**
- **Found during:** Task 2 smoke-test (Test 5 — clipboard restore test failed: paste after dismiss yielded the trigger text "BBB", not original "AAA")
- **Issue:** `clipboardManager.saveCurrentContents()` was called inside the 80ms `Task.sleep` block, after the source app had already written the selection ("BBB") to the pasteboard. The snapshot captured "BBB", so "restoring" it after dismiss just wrote "BBB" back.
- **Fix:** Moved `saveCurrentContents()` to before `Task.sleep` in `handleTrigger()`, so the snapshot captures whatever was in the clipboard before the trigger cycle began
- **Files modified:** `Transy/AppDelegate.swift`
- **Verification:** Smoke test re-run: copying "AAA", then triggering on "BBB", then dismissing → paste yielded "AAA". Confirmed working.
- **Committed in:** `3b544ee`

---

**Total deviations:** 2 auto-fixed (both Rule 1 — bugs discovered during live smoke test)
**Impact on plan:** Both fixes essential for core UX correctness. No scope creep.

## Issues Encountered

- `orderFront(nil)` vs `orderFrontRegardless()` — a subtle AppKit behavior difference for background agents; documented as a decision for future reference (Phase 3 popup updates will use same pattern)
- Clipboard snapshot timing — the 80ms delay is for reading the selection, not for protecting the snapshot; the snapshot must happen before the delay. The plan's pseudocode implied post-delay snapshot, but correct behavior requires pre-delay snapshot.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- Phase 2 is **complete**. All six success criteria verified by human smoke test.
- Phase 3 (Translation Loop) can begin: `PopupController.show(sourceText:onDismiss:)` and `AppState.isPopupVisible` are the integration points for the translation coordinator.
- `PopupView` is ready for Phase 3 update: change `.secondary` foreground to `.primary` when translation result arrives.
- No blockers. Phase 3 hard requirement (macOS 15+ for Apple Translation framework) is already the project deployment target.

---
*Phase: 02-trigger-popup*
*Completed: 2026-03-14*

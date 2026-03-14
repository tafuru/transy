---
phase: 02-trigger-popup
plan: "01"
subsystem: ui
tags: [swiftui, appkit, accessibility, permissions, nswindow, axisprocesstrusted]

# Dependency graph
requires:
  - phase: 01-app-shell
    provides: NSApp.activate() pattern for LSUIElement window surfacing
provides:
  - GuidanceView: SwiftUI permissions guidance content with Open System Settings button
  - GuidanceWindowController: AppKit singleton wrapping GuidanceView; AX-gated showIfNeeded(); trust polling; onPermissionGranted callback
affects: [02-03-PLAN.md, AppDelegate]

# Tech tracking
tech-stack:
  added: [ApplicationServices (AXIsProcessTrusted)]
  patterns:
    - Singleton NSWindowController with isReleasedWhenClosed=false for window reuse
    - MainActor.assumeIsolated in Timer callback for Swift 6 concurrency compliance
    - Trust polling via scheduledTimer invalidated on AXIsProcessTrusted() flip

key-files:
  created:
    - Transy/Permissions/GuidanceView.swift
    - Transy/Permissions/GuidanceWindowController.swift
  modified: []

key-decisions:
  - "showIfNeeded() never suppresses after first show — re-raises window on every failed trigger attempt (locked decision)"
  - "AXIsProcessTrusted() used directly; AXIsProcessTrustedWithOptions(prompt:true) explicitly avoided to bypass generic system prompt"
  - "Window level set to .floating so guidance appears above other apps without stealing focus unnecessarily"
  - "No project.yml changes needed — xcodegen auto-discovers Transy/Permissions/ subdirectory"

patterns-established:
  - "Re-entrant guidance window: every call re-raises; no 'already shown' tracking"
  - "Trust polling: 2s Timer, invalidated and hidden when AXIsProcessTrusted() returns true"
  - "onPermissionGranted callback wired at call site (AppDelegate) for post-grant auto-start"

requirements-completed: [TRIG-02]

# Metrics
duration: 1min
completed: 2026-03-14
---

# Phase 2 Plan 01: Permissions Guidance Subsystem Summary

**AX-gated NSWindowController singleton hosting a SwiftUI guidance card that re-appears on every failed trigger attempt and auto-dismisses via trust polling when Accessibility is granted**

## Performance

- **Duration:** ~1 min
- **Started:** 2026-03-14T09:21:30Z
- **Completed:** 2026-03-14T09:22:15Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Self-contained `GuidanceView` (SwiftUI) with headline, matter-of-fact instructions, and "Open System Settings" deep-link button — no app dependencies
- `GuidanceWindowController` singleton: AX-gated `showIfNeeded()` (no-op when trusted, shows window when not), re-entrant by design, lazy window construction, `.floating` level
- 2-second trust poll starts on window show; auto-dismisses and fires `onPermissionGranted` when `AXIsProcessTrusted()` flips true
- No duplicate timers: `guard trustPollTimer == nil` prevents re-entry on repeated `showIfNeeded()` calls
- Zero `project.yml` changes required — xcodegen auto-discovers `Transy/Permissions/` subdirectory

## Task Commits

Each task was committed atomically:

1. **Task 1: GuidanceView — SwiftUI permissions guidance content** - `a1d87ae` (feat)
2. **Task 2: GuidanceWindowController — AppKit singleton host with AX gate** - `2769df0` (feat)

## Files Created/Modified
- `Transy/Permissions/GuidanceView.swift` — SwiftUI card: headline + body instructions + "Open System Settings" button (NSWorkspace deep-link)
- `Transy/Permissions/GuidanceWindowController.swift` — NSWindowController singleton: AXIsProcessTrusted gate, showIfNeeded, trust polling, onPermissionGranted callback

## Decisions Made
- Used `AXIsProcessTrusted()` bare (not `withOptions prompt:true`) to ensure the custom guidance window is shown instead of the generic macOS system prompt
- `isReleasedWhenClosed = false` on NSWindow so the window instance is retained for reuse on subsequent `showIfNeeded()` calls
- `MainActor.assumeIsolated` in Timer callback — Swift 6 compliance: Timer fires on main thread, this asserts that guarantee without requiring an `async` hop
- No `project.yml` edit needed — xcodegen `sources: path: Transy` auto-discovers all subdirectories including new `Permissions/`

## Deviations from Plan
None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- `GuidanceWindowController.shared.showIfNeeded()` is ready for call from `MenuBarView` (Plan 02-03)
- `GuidanceWindowController.shared.onPermissionGranted` is ready for `AppDelegate` wiring to restart monitoring post-grant
- Validate Accessibility System Settings deep-link URL on macOS 15 during Plan 02-03 smoke test

---
*Phase: 02-trigger-popup*
*Completed: 2026-03-14*

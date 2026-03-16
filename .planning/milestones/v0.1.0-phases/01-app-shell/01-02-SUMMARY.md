---
phase: 01-app-shell
plan: 02
subsystem: ui
tags: [swiftui, menubarextra, macos, lsuielement, settings, activationpolicy]

# Dependency graph
requires:
  - phase: 01-app-shell-01
    provides: Compilable Transy.xcodeproj, Swift stubs for TransyApp/MenuBarView/SettingsView, LSUIElement Info.plist, no-sandbox config
provides:
  - Fully functional macOS menu bar icon (character.bubble, icon-only, no Dock presence)
  - Native dropdown menu with exactly Settings… (Cmd+,) + Divider + Quit Transy (Cmd+Q)
  - Placeholder settings window (320×120, single instance via Settings scene)
  - NSApp.activate() call before openSettings() to surface the window reliably
  - Runtime-verified: no Dock icon at launch, during use, or while Settings is open
affects:
  - 02-hotkey-monitor (attaches to AppDelegate hooks, relies on no-Dock policy)
  - 03-translation (adds content to SettingsView, extends MenuBarView)
  - All subsequent plans (menu bar shell is the user-visible host for all Phase 2+ features)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - MenuBarExtra(.menu) for native dropdown (not .window floating panel)
    - Settings scene for single-instance settings window (not WindowGroup)
    - NSApp.activate(ignoringOtherApps:true) before openSettings() on macOS 15 to surface the window
    - @Environment(\.openSettings) action for decoupled settings trigger from menu content

key-files:
  created: []
  modified:
    - Transy/TransyApp.swift
    - Transy/MenuBar/MenuBarView.swift
    - Transy/Settings/SettingsView.swift

key-decisions:
  - ".menuBarExtraStyle(.menu) is required — omitting it produces a floating .window panel, not a native dropdown"
  - "Settings scene (not WindowGroup) used for single-instance management, Cmd+, binding, and activation-policy safety"
  - "NSApp.activate() added before openSettings() — on macOS 15 the Settings window silently opens behind other apps without it"
  - "character.bubble SF Symbol chosen as menu bar icon — quiet, translation-appropriate, renders as adaptive template image"

patterns-established:
  - "NSApp.activate before openSettings: always call NSApp.activate() before openSettings() in an LSUIElement app on macOS 15+"
  - "Settings scene pattern: use Settings { ... } scene for any panel that must be single-instance and bound to Cmd+,"

requirements-completed: [APP-01]

# Metrics
duration: ~20min
completed: 2026-03-14
---

# Phase 01 Plan 02: Menu Bar Shell Summary

**Icon-only macOS menu bar agent with native dropdown (Settings… + Quit), placeholder settings window, and NSApp.activate fix for reliable window surfacing on macOS 15**

## Performance

- **Duration:** ~20 min
- **Started:** 2026-03-14T05:24:02Z
- **Completed:** 2026-03-14T05:44:07Z
- **Tasks:** 2 (1 auto + 1 human-verify checkpoint) + 1 auto-fix deviation
- **Files modified:** 3

## Accomplishments
- All three Swift source files finalized: TransyApp, MenuBarView, SettingsView match locked spec exactly
- `character.bubble` icon appears in menu bar; no Dock icon at launch, during use, or while Settings is open
- Native dropdown menu confirmed at runtime: Settings… (Cmd+,) + Divider + Quit Transy (Cmd+Q) — no extra items
- Settings window opens as single-instance native panel (320×120); Cmd+, shortcut works
- Quit exits cleanly, no zombie process
- No sandbox or entitlement errors in Console.app on launch
- Human smoke-test approved — all 13 checklist items passed

## Task Commits

Each task was committed atomically:

1. **Task 1: Finalize TransyApp, MenuBarView, SettingsView** — `48ae4f1` (feat)
2. **Deviation fix: activate app before openSettings** — `bd9e03a` (fix)
3. **Task 2: Runtime smoke test — human verified and approved** — (checkpoint, no code commit)

**Plan metadata:** _(this commit)_

## Files Created/Modified
- `Transy/TransyApp.swift` — `@main` App with `MenuBarExtra("Transy", systemImage: "character.bubble")`, `.menuBarExtraStyle(.menu)`, `Settings { SettingsView() }`, `@NSApplicationDelegateAdaptor`
- `Transy/MenuBar/MenuBarView.swift` — Settings… button (Cmd+,) with `NSApp.activate` + `openSettings()`, Divider, Quit Transy (Cmd+Q)
- `Transy/Settings/SettingsView.swift` — 320×120 placeholder VStack with "Transy" headline + secondary note

## Decisions Made
- **`.menuBarExtraStyle(.menu)` required:** Without it MenuBarExtra opens a floating `.window` panel instead of a native dropdown. This is not obvious from SwiftUI docs — locked in as a known-pitfall pattern.
- **`NSApp.activate` before `openSettings()`:** On macOS 15, calling `openSettings()` from an LSUIElement app without first activating the app causes the Settings window to open silently behind other windows. Fix: call `NSApp.activate()` immediately before `openSettings()`.
- **`Settings` scene over `WindowGroup`:** The `Settings` scene provides single-instance management, automatic Cmd+, binding, and safe activation-policy behavior — `WindowGroup` would require manual equivalents and risks Dock icon flashes.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] NSApp.activate() before openSettings() to surface Settings window**
- **Found during:** Task 2 runtime verification (smoke test)
- **Issue:** Clicking "Settings…" in the menu caused the Settings window to open behind other apps without gaining focus. The window was created but invisible to the user unless they used Exposé or clicked the window in Mission Control.
- **Fix:** Added `NSApp.activate()` immediately before `openSettings()` in `MenuBarView.swift`
- **Files modified:** `Transy/MenuBar/MenuBarView.swift`
- **Verification:** Settings window surfaces correctly on top of all other windows after click; re-verified in runtime smoke test, user approved
- **Committed in:** `bd9e03a`

---

**Total deviations:** 1 auto-fixed (Rule 1 - bug)
**Impact on plan:** Single-line fix in MenuBarView only. Essential for correct UX — without it the Settings window is effectively unreachable via normal interaction. No scope added.

## Issues Encountered
- **Settings window focus on macOS 15:** `openSettings()` alone is insufficient for LSUIElement apps on macOS 15 — window opens silently in background. Required `NSApp.activate()` prefix. This is a known macOS 15 behavior change; pattern documented for all future settings-triggering code in the app.

## User Setup Required
None — no external service configuration required.

## Next Phase Readiness
- Complete menu bar shell verified at runtime ✅
- No Dock presence under any condition confirmed ✅
- Settings window single-instance, correctly surfacing, Cmd+, bound ✅
- AppDelegate hook comments ready for Phase 2 hotkey monitor ✅
- Phase 1 (APP-01) requirement fully satisfied ✅
- Phase 2 (hotkey monitor) can proceed: sandbox-free, AppDelegate attachment point in place, menu bar host stable

---
*Phase: 01-app-shell*
*Completed: 2026-03-14*

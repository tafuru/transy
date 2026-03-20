---
phase: 06-popup-positioning
plan: 01
subsystem: popup-positioning
tags: [positioning, cursor-proximate, nswindow, resize-observation, nspanel]
dependency_graph:
  requires:
    - phase: 06-popup-positioning/00
      provides: PopupPositionCalculator.calculateOrigin
  provides:
    - Cursor-proximate popup placement in PopupController
    - Content resize observation with automatic repositioning
    - Edge-clamped positioning integrated into live popup panel
  affects: []
tech_stack:
  added: []
  patterns: [resize-observation-via-NotificationCenter, cursor-capture-at-trigger]
key_files:
  created: []
  modified:
    - Transy/Popup/PopupController.swift
decisions:
  - "Cursor location captured once at trigger time (NSEvent.mouseLocation) — popup stays anchored to original cursor position through content changes"
  - "NSWindow.didResizeNotification used for content height change observation — lightweight, no KVO or Combine needed"
patterns-established:
  - "Resize observation pattern: NotificationCenter observer on panel didResize → reposition with stored cursor"
  - "Observer lifecycle: remove on dismiss() and on re-trigger start to prevent stale/duplicate observers"
requirements-completed: [POP-06, POP-07]
metrics:
  duration: 8min
  completed: "2026-03-20T16:58:43Z"
  tasks_completed: 2
  tasks_total: 2
  files_created: 0
  files_modified: 1
---

# Phase 06 Plan 01: Wire Cursor-Proximate Positioning into PopupController — Summary

**PopupPositionCalculator wired into PopupController with cursor capture at trigger, NSWindow resize observation for content height changes, and resize observer lifecycle management on dismiss/re-trigger.**

## Performance

- **Duration:** ~8 min (including visual verification)
- **Started:** 2026-03-20T16:50:00Z
- **Completed:** 2026-03-20T16:58:43Z
- **Tasks:** 2 (1 auto + 1 checkpoint:human-verify)
- **Files modified:** 1

## Accomplishments

- Replaced fixed top-center popup placement with cursor-proximate positioning via PopupPositionCalculator
- Added NSWindow.didResizeNotification observer so popup repositions when content height changes (loading → result)
- Refactored `activeScreen()` to `screen(containing:)` accepting a CGPoint for targeted screen lookup
- Proper observer lifecycle: cleanup on dismiss and re-trigger prevents stale/duplicate observers
- All 7 visual verification scenarios passed (basic placement, edge clamping at all 4 edges, content resize, re-trigger)

## Task Commits

Each task was committed atomically:

1. **Task 1: Replace top-center placement with cursor-proximate positioning and resize observation** — `7f7e7a9` (feat)
2. **Task 2: Visual verification of cursor-proximate positioning** — checkpoint:human-verify, approved

## Files Created/Modified

- `Transy/Popup/PopupController.swift` — Wired PopupPositionCalculator into show(), added cursorAtTrigger/resizeObserver properties, repositionPanel() method, screen(containing:) refactor, removeResizeObserver() helper, deleted obsolete topCenterOrigin(for:)

## Decisions Made

1. **Cursor captured once at trigger time**: `NSEvent.mouseLocation` stored in `cursorAtTrigger` at the start of `show()`. The popup stays anchored to the original cursor position through content changes rather than tracking mouse movement.
2. **NSWindow.didResizeNotification for resize observation**: Lightweight notification-based approach — no KVO or Combine needed. Observer fires on any panel size change, triggering repositionPanel() which recalculates from stored cursor.

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- Phase 6 (Popup Positioning) is now fully complete: both Plan 00 (TDD calculator) and Plan 01 (integration) are done
- v0.2.0 milestone fully delivered: Phase 5 (Popup Layout) + Phase 6 (Popup Positioning) both complete
- All 4 v0.2.0 requirements satisfied: POP-04, POP-05, POP-06, POP-07

---
*Phase: 06-popup-positioning*
*Completed: 2026-03-20*

## Self-Check: PASSED

- [x] 06-01-SUMMARY.md exists
- [x] PopupController.swift exists with cursor-proximate positioning
- [x] Commit 7f7e7a9 exists
- [x] All tests pass (exit code 0)

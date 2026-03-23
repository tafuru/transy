---
phase: 08-first-launch-onboarding
plan: 01
subsystem: ui
tags: [swiftui, accessibility, onboarding, permissions, macos]

# Dependency graph
requires:
  - phase: 02-menu-bar
    provides: "GuidanceWindowController singleton with showIfNeeded/polling"
provides:
  - "Proactive AX guidance on launch — no user action needed to discover permission requirement"
  - "Enhanced GuidanceView with why-explanation and safe URL handling"
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Proactive permission check on app launch (showIfNeeded before startMonitoringIfNeeded)"
    - "Defensive URL construction with guard-let instead of force-unwrap"

key-files:
  created: []
  modified:
    - "Transy/AppDelegate.swift"
    - "Transy/Permissions/GuidanceView.swift"

key-decisions:
  - "AX permission state is sole determinant for showing guidance — no UserDefaults flag"
  - "Why-explanation and instruction text kept as separate Text views for clarity"

patterns-established:
  - "Proactive permission guidance: check on launch, not on user-triggered action"
  - "Safe URL construction: guard-let pattern for system deep links"

requirements-completed: [OBD-01, OBD-02]

# Metrics
duration: 1.2min
completed: 2026-03-23
---

# Phase 8 Plan 01: First-Launch Onboarding Summary

**Proactive AX guidance on launch with why-explanation text and safe System Settings deep link**

## Performance

- **Duration:** 72s (1.2 min)
- **Started:** 2026-03-23T13:16:55Z
- **Completed:** 2026-03-23T13:18:07Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Guidance window now appears immediately on launch when AX permission is missing — users never wonder why the app isn't working
- Added clear explanation of WHY Accessibility access is needed (double ⌘C shortcut detection)
- Fixed force-unwrap on System Settings URL with defensive guard-let pattern

## Task Commits

Each task was committed atomically:

1. **Task 1: Add proactive AX guidance check on launch** - `0d5fff6` (feat)
2. **Task 2: Enhance GuidanceView with why explanation and safe URL** - `6dd9099` (feat)

## Files Created/Modified
- `Transy/AppDelegate.swift` - Added showIfNeeded() call in applicationDidFinishLaunching before startMonitoringIfNeeded
- `Transy/Permissions/GuidanceView.swift` - Added why-explanation Text, separated instruction text, replaced URL force-unwrap with guard-let

## Decisions Made
None - followed plan as specified

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- First-launch onboarding complete, users will see guidance immediately when AX permission is missing
- Ready to proceed to Phase 9 (remaining milestone plans)

## Self-Check: PASSED

- All files exist (AppDelegate.swift, GuidanceView.swift, 08-01-SUMMARY.md)
- Commits 0d5fff6 and 6dd9099 verified in git log
- Content verified: showIfNeeded in AppDelegate, why explanation in GuidanceView, guard-let URL

---
*Phase: 08-first-launch-onboarding*
*Completed: 2026-03-23*

---
phase: 06-popup-positioning
plan: 00
subsystem: popup-positioning
tags: [tdd, positioning, geometry, pure-function]
dependency_graph:
  requires: []
  provides: [PopupPositionCalculator, calculateOrigin]
  affects: [PopupController]
tech_stack:
  added: []
  patterns: [pure-function-geometry, edge-clamping, flip-placement]
key_files:
  created:
    - Transy/Popup/PopupPositionCalculator.swift
    - TransyTests/PopupPositioningTests.swift
  modified: []
decisions:
  - PopupPositionCalculator uses Foundation types only (CGPoint, CGSize, CGRect) — no AppKit dependency for testability
metrics:
  duration: 97s
  completed: "2026-03-20T16:46:31Z"
  tasks_completed: 2
  tasks_total: 2
  files_created: 2
  files_modified: 0
---

# Phase 06 Plan 00: PopupPositionCalculator — TDD Summary

Pure positioning calculator with cursor-proximate placement, vertical flip on overflow, and horizontal/vertical edge-clamping using Foundation geometry types only.

## What Was Built

`PopupPositionCalculator.swift` — a static pure function `calculateOrigin` that computes popup panel origin from cursor location, panel size, and screen frame. The function:

1. Centers the popup horizontally on the cursor X position
2. Places it below the cursor with a configurable offset (default 8pt)
3. Flips above the cursor when below-placement would overflow the screen bottom
4. Clamps horizontal position to keep within screen edges with configurable margin
5. Clamps vertical position when a flipped popup overflows the screen top
6. Correctly handles non-zero screen origins (Dock/menu bar offsets)

## TDD Cycle

### RED Phase (commit: 9f7498a)
- Created `TransyTests/PopupPositioningTests.swift` with 9 test cases
- Tests covered: happy path, flip-above, left/right edge clamp, top overflow clamp, non-zero screen origin, combined flip+clamp, default constants
- Compilation failed: `PopupPositionCalculator` not found ✓

### GREEN Phase (commit: add6aff)
- Created `Transy/Popup/PopupPositionCalculator.swift` with minimal implementation
- All 9 tests passed on first run ✓
- No existing tests regressed ✓

### REFACTOR Phase
- Skipped — implementation is already minimal and clean (38 lines, single pure function)

## Test Coverage

| Test | Scenario | Status |
|------|----------|--------|
| 1 | Below cursor, centered horizontally | ✅ |
| 2 | Flip above when bottom overflows | ✅ |
| 3 | Left edge clamp | ✅ |
| 4 | Right edge clamp | ✅ |
| 5 | Flipped popup overflows top → clamp | ✅ |
| 6 | Non-zero screen origin (Dock offset) | ✅ |
| 7 | Bottom overflow with non-zero origin | ✅ |
| 8 | Bottom-right corner (flip + right clamp) | ✅ |
| 9 | Default constants are 8pt | ✅ |

## Deviations from Plan

None — plan executed exactly as written.

## Decisions Made

1. **Foundation-only dependency**: `PopupPositionCalculator` uses only `Foundation` types (`CGPoint`, `CGSize`, `CGRect`), keeping it free of AppKit for pure unit testability.

## Commits

| Hash | Type | Description |
|------|------|-------------|
| 9f7498a | test | Add failing tests for PopupPositionCalculator (RED) |
| add6aff | feat | Implement PopupPositionCalculator with edge-clamping (GREEN) |

## Self-Check: PASSED

- [x] PopupPositionCalculator.swift exists
- [x] PopupPositioningTests.swift exists
- [x] 06-00-SUMMARY.md exists
- [x] Commit 9f7498a exists
- [x] Commit add6aff exists

---
phase: 06-popup-positioning
verified: 2025-07-16T12:00:00Z
status: passed
score: 10/10 must-haves verified
re_verification: false
---

# Phase 6: Popup Positioning — Verification Report

**Phase Goal:** Popup appears near the user's cursor and stays fully visible on screen
**Verified:** 2025-07-16
**Status:** ✅ PASSED
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | calculateOrigin places popup below cursor with 8pt offset, horizontally centered on cursor X | ✓ VERIFIED | `PopupPositionCalculator.swift:20` — `belowY = cursorLocation.y - offset - panelSize.height`; `line 15` — `x = cursorLocation.x - panelSize.width / 2`; Test 1 validates (500,400) → (350,292) |
| 2 | calculateOrigin flips popup above cursor when below-placement would overflow bottom of screen visibleFrame | ✓ VERIFIED | `PopupPositionCalculator.swift:23-28` — flip logic when `belowY < screenFrame.minY + margin`; Tests 2, 7, 8 validate flip scenarios |
| 3 | calculateOrigin clamps horizontal position to keep popup within screen edges with 8pt margin | ✓ VERIFIED | `PopupPositionCalculator.swift:16-17` — `max(minX+margin)` and `min(maxX-width-margin)` clamps; Tests 3, 4 validate left/right edge |
| 4 | calculateOrigin clamps vertical position when flipped popup would overflow top of screen | ✓ VERIFIED | `PopupPositionCalculator.swift:30-31` — `aboveY + height > maxY - margin` → clamp; Test 5 validates (350,12) |
| 5 | calculateOrigin works correctly with non-zero screen origins (Dock/menu bar offsets) | ✓ VERIFIED | Calculator uses `screenFrame.minY`/`screenFrame.maxY` throughout (not hardcoded 0); Tests 6, 7 use non-zero origin (0,100,1000,700) |
| 6 | Popup appears below cursor, horizontally centered on cursor X, with 8pt offset | ✓ VERIFIED | `PopupController.swift:65-66` — captures `NSEvent.mouseLocation` then calls `repositionPanel()` which delegates to `PopupPositionCalculator.calculateOrigin` |
| 7 | Popup flips above cursor when bottom would overflow screen | ✓ VERIFIED | Wired through `repositionPanel()` → `PopupPositionCalculator.calculateOrigin` which contains flip logic |
| 8 | Popup never extends beyond screen edges regardless of cursor position | ✓ VERIFIED | Calculator applies horizontal clamping (lines 16-17) and vertical clamping (lines 23-33); all edge cases tested |
| 9 | Popup repositions correctly when content height changes (loading → result) | ✓ VERIFIED | `PopupController.swift:68-76` — `NSWindow.didResizeNotification` observer on panel calls `repositionPanel()` on main queue |
| 10 | Top edge stays anchored when popup grows downward on content change | ✓ VERIFIED | `calculateOrigin` places top edge at `cursorY - offset`; resize triggers recalculation from same `cursorAtTrigger` preserving anchor point |

**Score:** 10/10 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `Transy/Popup/PopupPositionCalculator.swift` | Pure positioning calculation — no AppKit dependency | ✓ VERIFIED | 38 lines, `import Foundation` only, exports `PopupPositionCalculator` struct with `calculateOrigin` static method and `defaultOffset`/`defaultMargin` constants |
| `TransyTests/PopupPositioningTests.swift` | Unit tests covering all positioning scenarios | ✓ VERIFIED | 132 lines, `@Suite("PopupPositionCalculator")` with 9 `@Test` cases covering happy path, flip, edge clamp, combined scenarios, non-zero origins, defaults |
| `Transy/Popup/PopupController.swift` | Cursor-proximate positioning with resize observation | ✓ VERIFIED | Contains `PopupPositionCalculator.calculateOrigin` call in `repositionPanel()`, `cursorAtTrigger` property, `resizeObserver` with `didResizeNotification`, old `topCenterOrigin` deleted |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `PopupPositioningTests.swift` | `PopupPositionCalculator.swift` | `@testable import Transy` + `PopupPositionCalculator.calculateOrigin` | ✓ WIRED | 8 calls to `PopupPositionCalculator.calculateOrigin` across 9 tests (test 9 checks constants) |
| `PopupController.swift` | `PopupPositionCalculator.swift` | `PopupPositionCalculator.calculateOrigin` in `repositionPanel()` | ✓ WIRED | Line 136: `PopupPositionCalculator.calculateOrigin(cursorLocation: cursorAtTrigger, panelSize: panel.frame.size, screenFrame: screen.visibleFrame)` |
| `PopupController.swift` | `NSWindow.didResizeNotification` | `NotificationCenter` observer on panel | ✓ WIRED | Lines 68-76: observer added in `show()`, calls `repositionPanel()` via `MainActor.assumeIsolated`; cleanup in `removeResizeObserver()` called from both `dismiss()` and `show()` re-trigger |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| POP-06 | 06-00, 06-01 | Popup appears near the mouse cursor position at trigger time instead of a fixed screen location | ✓ SATISFIED | `NSEvent.mouseLocation` captured in `show()`, passed to `calculateOrigin` which centers popup horizontally on cursor X and places 8pt below; pure logic tested in 9 unit tests |
| POP-07 | 06-00, 06-01 | Popup stays fully visible on screen even when cursor is near a screen edge (edge-clamping) | ✓ SATISFIED | `calculateOrigin` clamps left/right with margin, flips above on bottom overflow, clamps top on flip overflow; tested with left edge, right edge, bottom flip, top clamp, combined corner, non-zero origin scenarios |

No orphaned requirements found — REQUIREMENTS.md maps POP-06 and POP-07 to Phase 6, and both are claimed by plans 06-00 and 06-01.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| — | — | None found | — | — |

No TODO/FIXME/HACK/placeholder comments, no empty implementations, no console.log stubs, no stub returns in any of the three phase files.

### Commit Verification

| Hash | Description | Exists |
|------|-------------|--------|
| `9f7498a` | test(06-00): add failing tests for PopupPositionCalculator | ✓ Verified |
| `add6aff` | feat(06-00): implement PopupPositionCalculator with edge-clamping | ✓ Verified |
| `7f7e7a9` | feat(06-01): wire PopupPositionCalculator into PopupController | ✓ Verified |

### Refactoring Completeness

| Check | Status | Details |
|-------|--------|---------|
| `topCenterOrigin(for:)` deleted | ✓ | 0 occurrences in entire `Transy/` directory |
| `activeScreen()` refactored to `screen(containing:)` | ✓ | 0 occurrences of `activeScreen`, 1 of `screen(containing:)` |
| Resize observer cleanup on dismiss | ✓ | `removeResizeObserver()` called in `dismiss()` before `panel.orderOut(nil)` |
| Resize observer cleanup on re-trigger | ✓ | `removeResizeObserver()` called at start of new positioning in `show()` |

### Human Verification Required

### 1. Visual Cursor-Proximate Placement

**Test:** Trigger translation with cursor in the middle of the screen
**Expected:** Popup appears ~8pt below cursor, horizontally centered on cursor X
**Why human:** Requires visual confirmation of NSPanel position relative to actual cursor on a real screen

### 2. Bottom Edge Flip

**Test:** Move cursor near the bottom of the screen, trigger translation
**Expected:** Popup flips and appears ABOVE the cursor
**Why human:** Screen edge behavior requires real screen geometry and visual confirmation

### 3. Edge Clamping at All Edges

**Test:** Trigger translation with cursor at far left, far right, and near top (with forced flip)
**Expected:** Popup stays fully visible with ~8pt margin from screen edges
**Why human:** Visual confirmation of edge behavior with actual screen bounds

### 4. Content Resize Repositioning

**Test:** Trigger translation and observe loading → result transition
**Expected:** Popup repositions smoothly, top edge stays anchored, popup grows downward
**Why human:** Animation/transition behavior requires real-time visual observation

---

_Verified: 2025-07-16_
_Verifier: Claude (gsd-verifier)_

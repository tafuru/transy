# Phase 6: Popup Positioning - Context

**Gathered:** 2026-03-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Popup appears near the user's cursor and stays fully visible on screen. Replace the current fixed top-center placement (`topCenterOrigin`) with cursor-proximate positioning and edge-clamping. Layout/sizing (Phase 5) is not changed — only WHERE the popup appears.

Requirements: POP-06 (cursor-proximate placement), POP-07 (edge-clamping).

</domain>

<decisions>
## Implementation Decisions

### Cursor-relative placement
- Popup appears **below** the cursor (natural reading direction, like a tooltip)
- Vertical offset: **8pt** below the cursor position
- Horizontal alignment: cursor X coordinate is the **center** of the popup
- Cursor position captured via `NSEvent.mouseLocation` at `show()` time

### Edge-clamping strategy
- **Vertical (bottom edge)**: Flip to **above** the cursor when the popup would overflow the bottom of `visibleFrame`. Same 8pt offset above cursor.
- **Horizontal (left/right edges)**: Clamp so the popup stays within `visibleFrame` with a **minimum 8pt margin** from screen edges.
- **Vertical (top edge)**: If flipped above cursor and still overflows top, clamp to top of `visibleFrame` with 8pt margin.

### Position updates on content resize
- When popup content height changes (loading → result), **recalculate position** to ensure it stays within screen bounds.
- **Anchor: top edge fixed** — popup grows downward, not centered vertically.
- If the new height causes overflow, apply the same edge-clamping/flip rules.

### Claude's Discretion
- Whether to capture cursor position at trigger time (HotkeyMonitor) vs show() time — evaluate which gives better UX
- Internal refactoring of `topCenterOrigin()` → new positioning method
- How to observe content height changes for position recalculation (PreferenceKey, NSWindow frame observation, etc.)
- Test strategy (unit tests for positioning math vs integration)

</decisions>

<specifics>
## Specific Ideas

- Behavior should feel like macOS native tooltips — close to cursor, never clipped by screen edges
- The 8pt values (offset and margin) are consistent for a cohesive feel
- Flip decision should be binary (above or below) — no intermediate positions

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `PopupController.activeScreen()` — already finds the screen containing the cursor via `NSEvent.mouseLocation`. Reuse for edge-clamping bounds.
- `PopupController.topCenterOrigin(for:)` — replace entirely with new cursor-proximate logic.
- `ContentHeightPreferenceKey` in PopupView.swift — could notify PopupController when height changes.

### Established Patterns
- NSPanel with `.nonActivatingPanel` and `.orderFrontRegardless()` — popup never activates or steals focus.
- `hostingView.sizingOptions = .intrinsicContentSize` — panel auto-sizes to SwiftUI content.
- `screen.visibleFrame` used for bounds (excludes menu bar and Dock).

### Integration Points
- `PopupController.show()` line 59: `panel.setFrameOrigin(topCenterOrigin(for: panel))` — single call site to replace.
- Content height changes: SwiftUI `@State contentHeight` in `PopupText` drives `.frame(height:)`. Need to bridge this to PopupController for position recalculation.
- `AppDelegate.handleTrigger()` calls `popupController.show()` — could pass cursor position if needed.

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 06-popup-positioning*
*Context gathered: 2026-03-20*

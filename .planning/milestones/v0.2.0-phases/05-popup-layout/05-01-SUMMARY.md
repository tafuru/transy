---
phase: 05-popup-layout
plan: 01
subsystem: Popup UI
tags: [swiftui, scrollview, word-wrap, popup-layout]
---

# 05-01 Summary: Multi-line Wrapping and Scrolling

## What was built

Transformed PopupText from a fixed 4-line truncating display to a dynamic scrollable container:

- **Word wrapping**: Removed `.lineLimit(4)` and `.truncationMode(.tail)` — text wraps naturally
- **Vertical scrolling**: Wrapped Text in `ScrollView(.vertical)` — enables scrolling for long content
- **Dynamic sizing**: Window sizes to content up to 200pt max height
- **Wider popup**: Expanded from 380pt to 640pt width for readability

## Deviations

- **Width changed from 380pt to 640pt**: User requested ~1.5x wider popup during UAT checkpoint
- **Max height changed from 400pt to 200pt**: User preference during UAT
- **Layout approach adjusted**: Used `.frame(maxWidth: .infinity)` on Text instead of fixed width, with `.frame(width: 640)` on ScrollView — cleaner separation of content layout and container sizing

## Key decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Popup width | 640pt (was 380pt) | User feedback: wider is better for readability |
| Max height | 200pt (was 400pt) | User preference for more visible content |
| Frame chain | Separate `.frame(width:)` + `.frame(maxHeight:)` | SwiftUI doesn't support `width` + `maxHeight` in single `.frame()` call |

## Requirements

| ID | Status | Evidence |
|----|--------|----------|
| POP-04 | ✅ Satisfied | Text wraps across multiple lines, no truncation |
| POP-05 | ✅ Satisfied | ScrollView enables vertical scrolling when content exceeds 200pt |

## Test results

All 41 tests passed (4 PopupTextLayoutTests + 37 existing tests).

## key-files

### created
(none)

### modified
- `Transy/Popup/PopupView.swift` — PopupText view restructured with ScrollView
- `TransyTests/PopupTextLayoutTests.swift` — Updated width references in comments

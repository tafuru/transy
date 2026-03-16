# Phase 5: Popup Layout — Validation Architecture

**Phase:** 05 — Popup Layout
**Requirements:** POP-04, POP-05

## Validation Strategy

| Requirement | What to Validate | Method | Deterministic? |
|-------------|------------------|--------|----------------|
| POP-04 | Text wraps across multiple lines without truncation | Unit test: verify `.lineLimit` removed and Text allows unlimited lines | Yes |
| POP-05 | Vertical scrolling when content exceeds visible height | Unit test: verify ScrollView wrapping with maxHeight constraint | Yes |

## Test Plan

### Unit Tests (automated, deterministic)

1. **PopupText has no line limit** — Verify that PopupText renders Text without `.lineLimit(4)` or `.truncationMode(.tail)`.
2. **PopupText uses ScrollView** — Verify that long content is wrapped in `ScrollView(.vertical)`.
3. **PopupText respects maxHeight** — Verify that `.frame(maxHeight:)` is applied to constrain scroll region.

### Manual Verification (UAT)

1. Trigger translation of a short phrase → popup sizes to content (no unnecessary scroll)
2. Trigger translation of a paragraph → text wraps across multiple lines
3. Trigger translation of a very long text → vertical scrollbar appears and user can scroll

## Coverage Matrix

| Req ID | Automated Test | Manual UAT | Covered? |
|--------|---------------|------------|----------|
| POP-04 | PopupText line limit removal test | Multi-line wrap visual check | ✓ |
| POP-05 | ScrollView structure test | Long text scroll visual check | ✓ |

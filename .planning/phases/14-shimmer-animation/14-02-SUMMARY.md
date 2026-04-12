---
plan: 14-02
status: complete
started: 2026-04-12
completed: 2026-04-12
tasks_completed: 2
tasks_total: 2
---

## Summary

Wired `.shimmer()` modifier into `LoadingPopupText.body` in PopupView.swift, positioned between `PopupText` instantiation and `.onChange`/`.translationTask` modifiers. Visual verification confirmed:
- Gradient sweep animates left→right during loading state (SHM-01)
- No popup movement or resize during shimmer (SHM-02)
- Reduce Motion disables animation — static muted text shown (SHM-03)

## Key Changes

| File | Change |
|------|--------|
| Transy/Popup/PopupView.swift | Added `.shimmer()` call on line 119 inside `LoadingPopupText.body` |

## Decisions

- `.shimmer()` placed BEFORE `.onChange` and `.translationTask` to maintain correct modifier ordering
- User approved visual verification checkpoint

## Issues

None.

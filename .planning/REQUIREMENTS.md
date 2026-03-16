# Requirements: Transy

**Defined:** 2026-03-16
**Core Value:** Selected text turns into a natural translation almost instantly without breaking the user's reading flow.

## v0.2.0 Requirements

Requirements for popup UX improvements. Each maps to roadmap phases.

### Popup Layout

- [ ] **POP-04**: Popup displays translated text with word wrapping instead of single-line truncation (tests created, awaiting implementation)
- [ ] **POP-05**: Popup supports vertical scrolling when translated text exceeds the visible area (tests created, awaiting implementation)

### Popup Positioning

- [ ] **POP-06**: Popup appears near the mouse cursor position at trigger time instead of a fixed screen location
- [ ] **POP-07**: Popup stays fully visible on screen even when the cursor is near a screen edge (edge-clamping)

## Future Requirements

Deferred to a later milestone. Tracked but not in current roadmap.

- **HIST-01**: User can view a list of recent translations
- **UI-01**: User can customize the translation trigger shortcut
- **UI-02**: User can adjust popup font size

## Out of Scope

| Feature | Reason |
|---------|--------|
| Source + translation side-by-side | User chose translation-only display for v0.2.0 |
| Popup resize by dragging | Fixed scrollable size is simpler and sufficient |
| Multi-monitor cursor tracking | Defer until single-monitor UX is solid |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| POP-04 | Phase 5 | Tests created (05-00) |
| POP-05 | Phase 5 | Tests created (05-00) |
| POP-06 | Phase 6 | Pending |
| POP-07 | Phase 6 | Pending |

**Coverage:**
- v0.2.0 requirements: 4 total
- Mapped to phases: 4
- Unmapped: 0 ✓

---
*Requirements defined: 2026-03-16*
*Last updated: 2026-03-16 after 05-00-PLAN.md completion*

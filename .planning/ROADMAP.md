# Roadmap: Transy

## Milestones

- ✅ **v0.1.0 MVP** — Phases 1-4 (shipped 2026-03-16)
- 🚧 **v0.2.0 Popup UX Polish** — Phases 5-6 (in progress)

## Phases

<details>
<summary>✅ v0.1.0 MVP (Phases 1-4) — SHIPPED 2026-03-16</summary>

- [x] Phase 1: App Shell (2/2 plans) — completed 2026-03-14
- [x] Phase 2: Trigger & Popup (3/3 plans) — completed 2026-03-14
- [x] Phase 3: Translation Loop (2/2 plans) — completed 2026-03-15
- [x] Phase 4: Settings (2/2 plans) — completed 2026-03-15

Full details: [milestones/v0.1.0-ROADMAP.md](milestones/v0.1.0-ROADMAP.md)

</details>

### v0.2.0 Popup UX Polish

- [ ] **Phase 5: Popup Layout** - Multi-line wrapping and scrolling for long translations
- [ ] **Phase 6: Popup Positioning** - Cursor-proximate placement with edge-clamping

---

## Phase Details

### Phase 5: Popup Layout
**Goal**: Popup displays long translations gracefully with word wrapping and vertical scrolling

**Depends on**: Nothing (builds on existing popup infrastructure from v0.1.0)

**Requirements**: POP-04, POP-05

**Success Criteria** (what must be TRUE):
1. User sees translated text wrap across multiple lines instead of truncating with ellipsis
2. User can scroll vertically when translated text exceeds the visible popup height
3. User sees all translated content without manual window resizing (scrolling is automatic)

**Plans**: TBD

---

### Phase 6: Popup Positioning
**Goal**: Popup appears near the user's cursor and stays fully visible on screen

**Depends on**: Nothing (independent of Phase 5)

**Requirements**: POP-06, POP-07

**Success Criteria** (what must be TRUE):
1. User sees popup appear near the mouse cursor position where they triggered the translation
2. User sees popup stay fully visible when cursor is near screen edges (top, bottom, left, right)
3. User never sees popup clipped or positioned off-screen regardless of cursor location

**Plans**: TBD

---

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 5. Popup Layout | 0/? | Not started | - |
| 6. Popup Positioning | 0/? | Not started | - |

---

*Last updated: 2026-03-16 for v0.2.0 milestone*

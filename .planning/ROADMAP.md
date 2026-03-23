# Roadmap: Transy

## Milestones

- ✅ **v0.1.0 MVP** — Phases 1-4 (shipped 2026-03-16)
- ✅ **v0.2.0 Popup UX Polish** — Phases 5-6 (shipped 2026-03-21)
- 🚧 **v0.3.0 Onboarding & Settings** — Phases 7-9 (in progress)

## Phases

<details>
<summary>✅ v0.1.0 MVP (Phases 1-4) — SHIPPED 2026-03-16</summary>

- [x] Phase 1: App Shell (2/2 plans) — completed 2026-03-14
- [x] Phase 2: Trigger & Popup (3/3 plans) — completed 2026-03-14
- [x] Phase 3: Translation Loop (2/2 plans) — completed 2026-03-15
- [x] Phase 4: Settings (2/2 plans) — completed 2026-03-15

Full details: [milestones/v0.1.0-ROADMAP.md](milestones/v0.1.0-ROADMAP.md)

</details>

<details>
<summary>✅ v0.2.0 Popup UX Polish (Phases 5-6) — SHIPPED 2026-03-21</summary>

- [x] Phase 5: Popup Layout (2/2 plans) — completed 2026-03-16
- [x] Phase 6: Popup Positioning (2/2 plans) — completed 2026-03-20

Full details: [milestones/v0.2.0-ROADMAP.md](milestones/v0.2.0-ROADMAP.md)

</details>

### 🚧 v0.3.0 Onboarding & Settings (In Progress)

**Milestone Goal:** Improve first-run experience with automatic permission guidance and modernize the Settings UI to macOS standards with new features.

- [ ] **Phase 7: Settings UI Modernization** - Restructure Settings into macOS-standard tabbed window with grouped sections
- [ ] **Phase 8: First-Launch Onboarding** - Automatically guide new users through Accessibility permission setup
- [ ] **Phase 9: General Settings Features** - Add Launch at Login and popup auto-dismiss settings

## Phase Details

### Phase 7: Settings UI Modernization
**Goal**: Users interact with a macOS-standard tabbed Settings window with properly grouped sections
**Depends on**: Phase 6 (v0.2.0 complete)
**Requirements**: SET-01, SET-02
**Success Criteria** (what must be TRUE):
  1. User sees General and About tabs in the Settings window, matching macOS Settings conventions
  2. User sees settings controls organized in bordered grouped sections within each tab
  3. Existing target language picker remains functional within the new General tab layout
**Plans**: 1 plan

Plans:
- [ ] 07-01-PLAN.md — Restructure Settings into macOS-standard tabbed window with General and About tabs using Form+Section grouped layout

### Phase 8: First-Launch Onboarding
**Goal**: New users receive Accessibility permission guidance automatically without needing to discover it
**Depends on**: Phase 7
**Requirements**: OBD-01, OBD-02
**Success Criteria** (what must be TRUE):
  1. User launching Transy for the first time sees the Accessibility permission guidance window automatically
  2. User can click a button in the guidance to open System Settings directly to the Accessibility pane
  3. User who already has Accessibility permission granted does not see the guidance window on launch
**Plans**: 1 plan

Plans:
- [ ] 08-01-PLAN.md — Proactive AX guidance on launch + enhanced GuidanceView content

### Phase 9: General Settings Features
**Goal**: Users can customize app behavior with launch-at-login setting
**Depends on**: Phase 7
**Requirements**: SET-03
**Success Criteria** (what must be TRUE):
  1. User can toggle "Launch at Login" in General settings and Transy starts automatically on next macOS login
  2. Toggle reflects actual system state (SMAppService.mainApp.status)
**Plans**: 1 plan

Plans:
- [ ] 09-01-PLAN.md — Add Launch at Login toggle with ServiceManagement framework

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. App Shell | v0.1.0 | 2/2 | Complete | 2026-03-14 |
| 2. Trigger & Popup | v0.1.0 | 3/3 | Complete | 2026-03-14 |
| 3. Translation Loop | v0.1.0 | 2/2 | Complete | 2026-03-15 |
| 4. Settings | v0.1.0 | 2/2 | Complete | 2026-03-15 |
| 5. Popup Layout | v0.2.0 | 2/2 | Complete | 2026-03-16 |
| 6. Popup Positioning | v0.2.0 | 2/2 | Complete | 2026-03-20 |
| 7. Settings UI Modernization | v0.3.0 | 0/0 | Not started | - |
| 8. First-Launch Onboarding | v0.3.0 | 0/0 | Not started | - |
| 9. General Settings Features | v0.3.0 | 0/0 | Not started | - |

---

*Last updated: 2026-03-21 — v0.3.0 roadmap created*

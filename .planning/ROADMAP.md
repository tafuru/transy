# Roadmap: Transy

## Milestones

- ✅ **v0.1.0 MVP** — Phases 1-4 (shipped 2026-03-16)
- ✅ **v0.2.0 Popup UX Polish** — Phases 5-6 (shipped 2026-03-21)
- ✅ **v0.3.0 Onboarding & Settings** — Phases 7-9 (shipped 2026-03-25)
- ✅ **v0.4.0 DevOps & Improvements** — Phases 10-13 (shipped 2026-04-04)
- 🚧 **v0.5.0 Translation Quality** — Phases 14-16 (in progress)

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

<details>
<summary>✅ v0.3.0 Onboarding & Settings (Phases 7-9) — SHIPPED 2026-03-25</summary>

- [x] Phase 7: Settings UI Modernization (1/1 plans) — completed 2026-03-23
- [x] Phase 8: First-Launch Onboarding (1/1 plans) — completed 2026-03-23
- [x] Phase 9: General Settings Features (1/1 plans) — completed 2026-03-25

Full details: [milestones/v0.3.0-ROADMAP.md](milestones/v0.3.0-ROADMAP.md)

</details>

<details>
<summary>✅ v0.4.0 DevOps & Improvements (Phases 10-13) — SHIPPED 2026-04-04</summary>

- [x] Phase 10: CI Pipeline (2/2 plans) — completed 2026-03-27
- [x] Phase 11: Release Automation (1/1 plans) — completed 2026-03-29
- [x] Phase 12: Clipboard Monitoring (2/2 plans) — completed 2026-04-04
- [x] Phase 13: Translation Download UI (1/1 plans) — completed 2026-04-04

Full details: [milestones/v0.4.0-ROADMAP.md](milestones/v0.4.0-ROADMAP.md)

</details>

### 🚧 v0.5.0 Translation Quality

- [x] **Phase 14: Shimmer Animation** — Animated skeleton shimmer during translation loading state (completed 2026-04-12)
- [ ] **Phase 15: Chunked Translation** — Split long text at sentence boundaries and translate as a batch
- [ ] **Phase 16: Pivot Translation** — Chain source→EN→target when language pair is unsupported

## Phase Details

### Phase 14: Shimmer Animation
**Goal**: Users see a smooth animated skeleton shimmer while translation is in progress, with no jarring layout shifts
**Depends on**: Phase 13
**Requirements**: SHM-01, SHM-02, SHM-03
**Success Criteria** (what must be TRUE):
  1. A shimmer animation plays over the loading-state text from the moment translation begins until the result appears
  2. Showing or hiding the shimmer does not change the popup's layout dimensions (no resize notification storm)
  3. When System Preferences → Accessibility → Reduce Motion is enabled, the shimmer is replaced with a static placeholder — no animation plays
**Plans**: 2 plans

Plans:
- [x] 14-01-PLAN.md — Create ShimmerModifier ViewModifier + unit tests
- [x] 14-02-PLAN.md — Wire shimmer into popup loading state + visual verification

**UI hint**: yes

---

### Phase 15: Chunked Translation
**Goal**: Texts longer than 200 characters are split at sentence boundaries and translated as a single batch, returning a correctly ordered result
**Depends on**: Phase 14
**Requirements**: CHK-01, CHK-02, CHK-03
**Success Criteria** (what must be TRUE):
  1. A text of 201+ characters is split into sentence-boundary chunks via `NLTokenizer` and all chunks are submitted as one `translations(from:)` batch call
  2. The translated chunks are recombined in input order — the result reads as continuous prose regardless of chunk count
  3. A text of ≤200 characters is translated directly without any chunking (single-call path, no overhead)
**Plans**: TBD (estimated 2 plans)

---

### Phase 16: Pivot Translation
**Goal**: When Apple Translation reports an unsupported language pair, the app silently chains two translations through English so the user still gets a result
**Depends on**: Phase 15
**Requirements**: PIV-01, PIV-02, PIV-03
**Success Criteria** (what must be TRUE):
  1. Translating a language pair not supported by Apple Translation (e.g. JP→DE) produces a correct result via the source→EN→target chain — no error shown to the user
  2. The shimmer animation plays continuously across both pivot legs — the popup never flickers or shows a partial state between legs
  3. When the pivot path also fails (EN→target unsupported), a clear error message is displayed instead of a blank or crashed popup
**Plans**: TBD (estimated 2 plans)

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. App Shell | v0.1.0 | 2/2 | Complete | 2026-03-14 |
| 2. Trigger & Popup | v0.1.0 | 3/3 | Complete | 2026-03-14 |
| 3. Translation Loop | v0.1.0 | 2/2 | Complete | 2026-03-15 |
| 4. Settings | v0.1.0 | 2/2 | Complete | 2026-03-15 |
| 5. Popup Layout | v0.2.0 | 2/2 | Complete | 2026-03-16 |
| 6. Popup Positioning | v0.2.0 | 2/2 | Complete | 2026-03-20 |
| 7. Settings UI Modernization | v0.3.0 | 1/1 | Complete | 2026-03-23 |
| 8. First-Launch Onboarding | v0.3.0 | 1/1 | Complete | 2026-03-23 |
| 9. General Settings Features | v0.3.0 | 1/1 | Complete | 2026-03-25 |
| 10. CI Pipeline | v0.4.0 | 2/2 | Complete | 2026-03-27 |
| 11. Release Automation | v0.4.0 | 1/1 | Complete | 2026-03-29 |
| 12. Clipboard Monitoring | v0.4.0 | 2/2 | Complete | 2026-04-04 |
| 13. Translation Download UI | v0.4.0 | 1/1 | Complete | 2026-04-04 |
| 14. Shimmer Animation | v0.5.0 | 2/2 | Complete   | 2026-04-12 |
| 15. Chunked Translation | v0.5.0 | 0/2 | Not started | — |
| 16. Pivot Translation | v0.5.0 | 0/2 | Not started | — |

---

*Last updated: 2026-04-04 — v0.5.0 roadmap created (phases 14-16)*

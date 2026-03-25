# Roadmap: Transy

## Milestones

- ✅ **v0.1.0 MVP** — Phases 1-4 (shipped 2026-03-16)
- ✅ **v0.2.0 Popup UX Polish** — Phases 5-6 (shipped 2026-03-21)
- ✅ **v0.3.0 Onboarding & Settings** — Phases 7-9 (shipped 2026-03-25)
- 🚧 **v0.4.0 DevOps & Improvements** — Phases 10-13 (in progress)

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

### 🚧 v0.4.0 DevOps & Improvements

**Milestone Goal:** Establish CI/CD pipeline, automate releases with DMG packaging, add permission-free clipboard monitoring trigger, and simplify translation model downloads.

- [ ] **Phase 10: CI Pipeline** - GitHub Actions workflow with SwiftLint, SwiftFormat, build, and test on PRs
- [ ] **Phase 11: Release Automation** - Release-triggered workflow that builds, packages DMG, and uploads to GitHub Release
- [ ] **Phase 12: Clipboard Monitoring** - Permission-free trigger mode via NSPasteboard polling with Settings UI
- [ ] **Phase 13: Translation Download UI** - Framework-native model download prompt replaces manual System Settings guidance

## Phase Details

### Phase 10: CI Pipeline
**Goal**: PRs to main are automatically validated for code style and build correctness
**Depends on**: Nothing (first phase of v0.4.0)
**Requirements**: CI-01, CI-02, CI-03, CI-04
**Success Criteria** (what must be TRUE):
  1. Opening a PR to main triggers SwiftLint and SwiftFormat checks that report violations as inline annotations on the PR diff
  2. Opening a PR to main triggers an xcodebuild build that catches compilation errors
  3. Opening a PR to main triggers xcodebuild tests that catch test failures
  4. CI workflow uses concurrency groups to cancel stale runs and completes with clear pass/fail status
**Plans**: TBD

### Phase 11: Release Automation
**Goal**: Creating a GitHub Release automatically builds a DMG and uploads it as a release asset
**Depends on**: Phase 10 (shares XcodeGen/xcodebuild patterns)
**Requirements**: REL-01, REL-02, REL-03
**Success Criteria** (what must be TRUE):
  1. Creating a GitHub Release from the UI triggers an automated workflow that builds the app in Release configuration
  2. The workflow produces a DMG containing Transy.app with a drag-to-Applications layout
  3. The DMG is uploaded as an asset on the GitHub Release with auto-generated release notes
**Plans**: TBD

### Phase 12: Clipboard Monitoring
**Goal**: Users can translate copied text without Accessibility permission by enabling clipboard monitoring as an alternative trigger mode
**Depends on**: Nothing (independent app feature)
**Requirements**: CLB-01, CLB-02, CLB-03, CLB-04
**Success Criteria** (what must be TRUE):
  1. With clipboard monitoring enabled, copying text in any app triggers a translation popup within ~500ms
  2. User can switch between "Double ⌘C" and "Clipboard monitoring" trigger modes in Settings
  3. Password manager entries (concealed type) and transient clipboard content are silently skipped
  4. Transy's own clipboard writes do not re-trigger translation
**Plans**: TBD
**UI hint**: yes

### Phase 13: Translation Download UI
**Goal**: Missing translation models are handled by the framework's built-in download prompt instead of manual System Settings navigation
**Depends on**: Nothing (independent app feature)
**Requirements**: TDL-01
**Success Criteria** (what must be TRUE):
  1. When a required translation model is not installed, the system download prompt appears automatically during translation
  2. The manual "Open Language & Region" guidance is replaced by the framework-native download flow
**Plans**: TBD
**UI hint**: yes

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
| 10. CI Pipeline | v0.4.0 | 0/? | Not started | - |
| 11. Release Automation | v0.4.0 | 0/? | Not started | - |
| 12. Clipboard Monitoring | v0.4.0 | 0/? | Not started | - |
| 13. Translation Download UI | v0.4.0 | 0/? | Not started | - |

---

*Last updated: 2026-03-25 — v0.4.0 roadmap created*

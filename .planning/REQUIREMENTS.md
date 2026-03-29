# Requirements: Transy

**Defined:** 2026-03-25
**Core Value:** Selected text turns into a natural translation almost instantly without breaking the user's reading flow.

## v0.4.0 Requirements

Requirements for DevOps & Improvements milestone. Each maps to roadmap phases.

### CI (Continuous Integration)

- [x] **CI-01**: PR to main triggers SwiftLint check on project sources
- [x] **CI-02**: PR to main triggers SwiftFormat check on project sources
- [x] **CI-03**: PR to main triggers xcodebuild build for macOS
- [x] **CI-04**: PR to main triggers xcodebuild test for macOS

### Release Automation

- [x] **REL-01**: Creating a GitHub Release triggers automated build and DMG creation workflow
- [x] **REL-02**: Release workflow creates DMG with drag-to-Applications layout
- [x] **REL-03**: Release workflow uploads DMG as a Release asset

### Clipboard Monitoring

- [ ] **CLB-01**: Clipboard monitoring detects new text via NSPasteboard.general.changeCount polling
- [ ] **CLB-02**: User can select trigger mode in Settings (clipboard monitoring vs double ⌘C)
- [ ] **CLB-03**: Clipboard monitoring skips concealed and transient pasteboard types
- [ ] **CLB-04**: Self-originated clipboard changes are ignored to prevent re-trigger loops

### Translation Download UI

- [ ] **TDL-01**: Translation framework's built-in download UI replaces manual System Settings guidance

## Future Requirements

None deferred for this milestone.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Code signing & Notarization | Adds significant complexity; ship unsigned first, add when broader distribution needed |
| DerivedData caching in CI | Marginal gain for Transy's small codebase; revisit if build times grow |
| Hybrid clipboard notification UI | Subtle badge instead of full popup adds UI complexity; defer |
| Popup auto-dismiss timer | Deprioritized; clipboard monitoring mode makes auto-dismiss less relevant |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| CI-01 | Phase 10 | Complete |
| CI-02 | Phase 10 | Complete |
| CI-03 | Phase 10 | Complete |
| CI-04 | Phase 10 | Complete |
| REL-01 | Phase 11 | Complete |
| REL-02 | Phase 11 | Complete |
| REL-03 | Phase 11 | Complete |
| CLB-01 | Phase 12 | Pending |
| CLB-02 | Phase 12 | Pending |
| CLB-03 | Phase 12 | Pending |
| CLB-04 | Phase 12 | Pending |
| TDL-01 | Phase 13 | Pending |

**Coverage:**
- v0.4.0 requirements: 12 total
- Mapped to phases: 12
- Unmapped: 0 ✓

---
*Requirements defined: 2026-03-25*
*Last updated: 2026-03-25 after roadmap creation*

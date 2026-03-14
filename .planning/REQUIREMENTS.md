# Requirements: Transy

**Defined:** 2026-03-14
**Core Value:** Selected text turns into a natural translation almost instantly without breaking the user's reading flow.

## v1 Requirements

Requirements for the initial release. Each maps to roadmap phases.

### Trigger & Capture

- [ ] **TRIG-01**: User can trigger translation of selected text in another macOS app by pressing `Command+C` twice within the supported interval.
- [x] **TRIG-02**: User is guided to grant the required macOS permissions when the trigger cannot monitor key events.
- [ ] **TRIG-03**: User can keep their previous clipboard contents after translation is triggered.

### Popup Experience

- [ ] **POP-01**: User sees a floating translation popup that does not take focus away from the current app.
- [ ] **POP-02**: User sees the selected source text immediately in a muted loading-state style while translation is in progress.
- [ ] **POP-03**: User can dismiss the popup with `Escape` or by clicking outside it.

### Translation

- [ ] **TRAN-01**: User receives an on-device Apple Translation framework translation of the selected text into the configured target language.
- [ ] **TRAN-02**: User does not need to choose the source language manually; the source language is detected automatically.
- [ ] **TRAN-03**: User sees the translated text replace the loading placeholder in the same popup when translation completes.

### App Shell & Settings

- [x] **APP-01**: User can access Transy from the macOS menu bar without a Dock icon.
- [ ] **APP-02**: User can choose the target translation language in a settings window.
- [ ] **APP-03**: User is guided to download any Apple translation models required for the selected language pair when they are not yet available on the device.

## v2 Requirements

Deferred to a future release. Tracked but not in the current roadmap.

### Workflow Convenience

- **FLOW-01**: User can launch Transy automatically at login.
- **FLOW-02**: User can copy the translated text directly from the popup.
- **FLOW-03**: User can adjust the double-press timing threshold for the translation trigger.

### Provider Extensions

- **PROV-01**: User can choose between Apple Translation and external providers in settings.
- **PROV-02**: User can fall back to an external provider when an on-device language pair is unavailable.

### Advanced UI

- **UI-01**: User sees the popup positioned near the current selection instead of a fixed screen location.

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Translation history | Breaks the ambient, private, "glance and continue" workflow and adds storage/privacy concerns |
| Manual text input | Introduces a second product mode and makes the popup heavier than intended |
| OCR / screenshot translation | High-complexity feature outside the selected-text translation core loop |
| Custom shortcut remapping | Not needed before validating the fixed double-`Command+C` trigger |
| Team/shared workflows | The current product is optimized for a personal reading workflow |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| APP-01 | Phase 1 — App Shell | Complete |
| TRIG-01 | Phase 2 — Trigger & Popup | Pending |
| TRIG-02 | Phase 2 — Trigger & Popup | Complete |
| TRIG-03 | Phase 2 — Trigger & Popup | Pending |
| POP-01 | Phase 2 — Trigger & Popup | Pending |
| POP-02 | Phase 2 — Trigger & Popup | Pending |
| POP-03 | Phase 2 — Trigger & Popup | Pending |
| TRAN-01 | Phase 3 — Translation Loop | Pending |
| TRAN-02 | Phase 3 — Translation Loop | Pending |
| TRAN-03 | Phase 3 — Translation Loop | Pending |
| APP-02 | Phase 4 — Settings | Pending |
| APP-03 | Phase 4 — Settings | Pending |

**Coverage:**
- v1 requirements: 12 total
- Mapped to phases: 12
- Unmapped: 0 ✓

---
*Requirements defined: 2026-03-14*
*Last updated: 2026-03-14 after initial definition*

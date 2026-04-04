# Requirements: Transy

**Defined:** 2026-04-04
**Core Value:** Selected text turns into a natural translation almost instantly without breaking the user's reading flow.

## v0.5.0 Requirements

Requirements for Translation Quality milestone. Each maps to roadmap phases.

### Shimmer Animation

- [ ] **SHM-01**: Translation loading state shows a shimmer/skeleton animation
- [ ] **SHM-02**: Shimmer is zero-layout-impact (does not trigger NSPanel resize)
- [ ] **SHM-03**: Shimmer is disabled and falls back to static display when Reduce Motion is enabled

### Chunked Translation

- [ ] **CHK-01**: Text longer than 200 characters is split at sentence boundaries (NLTokenizer) before translation
- [ ] **CHK-02**: Batch `translations(from:)` API is used; results are joined in input order
- [ ] **CHK-03**: Text of 200 characters or fewer bypasses chunking and is translated directly (short-text bypass)

### Pivot Translation

- [ ] **PIV-01**: On `unsupportedLanguagePairing` error, automatically falls back to a source→EN→target two-leg chain
- [ ] **PIV-02**: Shimmer continues throughout the entire pivot sequence (seamless to the user)
- [ ] **PIV-03**: If the pivot also fails (EN path unavailable), an appropriate error message is shown

## Future Requirements

- Translation history / recent translations
- Code signing and notarization for broader distribution
- Popup customization (font size, theme)
- Translation cancellation latency improvement (requires macOS 26+)

## Out of Scope

| Feature | Reason |
|---------|--------|
| "Translating via English…" progress label | Exposes internal pivot logic needlessly; users don't need to know the implementation |
| Parallel chunk TaskGroup | Over-engineered; `translations(from:)` batch API handles ordering and likely parallelizes internally |
| Per-chunk error recovery | Two real failure modes (unsupported pair → pivot, transient → error message) handled at whole-request level |
| Proactive LanguageAvailability.status() preflight | Removed in v0.4.0 to avoid double ML inference; keep the error-driven pivot approach |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| SHM-01 | Phase 14 | Pending |
| SHM-02 | Phase 14 | Pending |
| SHM-03 | Phase 14 | Pending |
| CHK-01 | Phase 15 | Pending |
| CHK-02 | Phase 15 | Pending |
| CHK-03 | Phase 15 | Pending |
| PIV-01 | Phase 16 | Pending |
| PIV-02 | Phase 16 | Pending |
| PIV-03 | Phase 16 | Pending |

**Coverage:**
- v0.5.0 requirements: 9 total
- Mapped to phases: 9
- Unmapped: 0 ✓

---
*Requirements defined: 2026-04-04*

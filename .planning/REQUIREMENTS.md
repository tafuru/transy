# Requirements: Transy

**Defined:** 2026-04-04
**Core Value:** Selected text turns into a natural translation almost instantly without breaking the user's reading flow.

## v0.5.0 Requirements

Requirements for Translation Quality milestone. Each maps to roadmap phases.

### Shimmer Animation

- [ ] **SHM-01**: 翻訳中（loading状態）にshimmer/skeleton animationが表示される
- [ ] **SHM-02**: Shimmerはzero-layout-impact（NSPanelのリサイズを誘発しない）
- [ ] **SHM-03**: Reduce Motionが有効な場合はshimmerを無効化し静的表示にフォールバック

### Chunked Translation

- [ ] **CHK-01**: テキストが200文字を超える場合、文章境界で分割して翻訳する（NLTokenizer使用）
- [ ] **CHK-02**: translations(from:) バッチAPIを使用し、結果を入力順に結合する
- [ ] **CHK-03**: 200文字以下のテキストは分割せず直接翻訳する（short-text bypass）

### Pivot Translation

- [ ] **PIV-01**: unsupportedLanguagePairingエラー検出時に、source→EN→targetの2段階翻訳にフォールバックする
- [ ] **PIV-02**: Pivot中もshimmerが継続表示される（ユーザーにはシームレスに見える）
- [ ] **PIV-03**: Pivot失敗（EN経由でも不可）の場合は適切なエラーメッセージを表示する

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

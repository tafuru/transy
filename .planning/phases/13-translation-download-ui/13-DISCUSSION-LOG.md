# Phase 13: Translation Download UI - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-04
**Phase:** 13-translation-download-ui
**Areas discussed:** Download prompt behavior, Settings guidance removal

---

## Todo Cross-Reference

| Todo | Relevance | Folded |
|------|-----------|--------|
| Add translation model install guidance | 0.6 | ✓ |
| Track translation cancellation latency | 0.6 | ✓ |

**User's choice:** Include both todos in Phase 13 scope.

---

## Download Prompt Behavior

### Sub-topic: Framework API Investigation

User requested investigation before deciding approach. Research conducted on Apple Translation framework APIs:

**Findings:**
1. `.translationTask()` + `session.translate()` — Framework automatically prompts for model download when needed (confirmed by Apple documentation: "the framework asks a person for permission to download the language translation models, if necessary")
2. `.translationPresentation(isPresented:text:)` — System translation overlay UI, but incompatible with Transy's custom popup UX
3. `prepareTranslation()` — Available for pre-downloading, not needed for this scope

| Option | Description | Selected |
|--------|-------------|----------|
| フレームワークに任せる | `.missingModel` 短絡を外し、`session.translate()` にフレームワーク自動ダウンロードUIを任せる | ✓ |
| 明示的に制御 | `.translationPresentation()` 修飾子で任意のタイミングでダウンロードシートを表示 | |
| 調査先行 | Apple Translation frameworkのダウンロードUI APIの現状を先に調査 | (initial selection, led to research) |

**User's choice:** フレームワークに任せる（推奨）— `.missingModel` 短絡を外し、`session.translate()` が自動ダウンロードUIを表示
**Notes:** Current code blocks framework download UI by short-circuiting on preflight `.missingModel` result. Removing this short-circuit is the minimal change needed.

---

## Settings Guidance Removal

| Option | Description | Selected |
|--------|-------------|----------|
| 完全削除 | TranslationModelGuidance、MissingModelContext、SettingsのガイダンスUIをすべて削除 | ✓ |
| フォールバックとして残す | フレームワークダウンロード失敗時のSettingsガイダンスを残す | |

**User's choice:** 完全削除（推奨）— TranslationModelGuidance、MissingModelContext、SettingsのガイダンスUIをすべて削除
**Notes:** Framework handles download UI natively, making manual guidance redundant.

---

## Agent's Discretion

- Whether to completely remove `TranslationAvailabilityClient.preflight()` or just simplify it (remove `.missingModel` handling)
- How to handle cancellation latency investigation (D-07) — scope and depth

## Deferred Ideas

None — discussion stayed within phase scope.

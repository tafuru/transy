# Phase 16: Pivot Translation — Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-17
**Phase:** 16-pivot-translation
**Areas discussed:** Pivot+Chunked interaction, Error handling, Relay language

---

## Pivot + Chunked Interaction

| Option | Description | Selected |
|--------|-------------|----------|
| 1回検出→全チャンクピボット | 最初のチャンクで非対応を検出したら、残り全チャンクを最初からEN経由で翻訳 | ✓ |
| チャンクごとに独立検出 | 各チャンクが個別にエラー→ピボット。シンプルだが無駄な呼び出しが発生 | |

**User's choice:** 1回検出→全チャンクピボット
**Notes:** ユーザーから「最初のチャンクで言語検出に失敗する可能性」について質問あり。検討の結果、最大3チャンクまで再試行する方針に合意。`unsupportedLanguagePairing` は言語ペアレベルのエラーなのでチャンク内容に依存せず安全。`unableToIdentifyLanguage` の場合のみリトライが有効。

---

## Error Handling (PIV-03)

| Option | Description | Selected |
|--------|-------------|----------|
| 現行メッセージをそのまま使用 | "This language pair isn't supported." — シンプル、ピボット内部を露出しない | ✓ |
| ピボット試行を明示するメッセージ | 「英語経由の翻訳も失敗しました」 | |

**User's choice:** 現行メッセージをそのまま使用
**Notes:** ユーザーはメッセージが英語であることを確認。ローカライズは別フェーズのスコープとして認識済み。

---

## Relay Language

| Option | Description | Selected |
|--------|-------------|----------|
| 英語固定 | シンプル。Apple Translationで最も多くのペアをカバー | ✓ |
| 設定可能 | ユーザーが中継言語を選べる。柔軟だが複雑化 | |

**User's choice:** 英語固定
**Notes:** v0.5.0では英語固定で十分。

---

## Agent's Discretion

- `translationAction` のリファクタリング構造
- ピボットロジックの分離方法（ヘルパー関数 vs インライン）
- テスト構造とモック戦略

## Deferred Ideas

- Translation Model Routing & Popup Dismiss — 次のマイルストーンで対応（フェーズ16スコープ外と判断）
- エラーメッセージのローカライズ — 別フェーズ
- 設定可能な中継言語 — 需要があれば将来検討

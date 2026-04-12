# Phase 15: Chunked Translation — Discussion Log

**Date:** 2026-04-12
**Participants:** User + AI

## Gray Areas Discussed

### 1. Chunking Threshold & Granularity
- **Q:** 200文字の閾値設定について
- **A:** 200文字固定でOK — 文境界で分割するので実際は各チャンクが200前後になる

- **Q:** 文単位で個別リクエスト vs 200文字以下のチャンクにグループ化
- **A:** 文をまとめて200文字以下のチャンクにグループ化 — リクエスト数を減らしてオーバーヘッド削減

- **Q:** バッチ内の一部のチャンクが失敗した場合
- **A:** 全体を失敗としてエラー表示 — シンプル、中途半端な結果より明確

- **Q:** チャンクの結合時のセパレーター
- **A:** 元のテキストの区切りを保持 — 改行やスペースをそのまま維持して結合

### 2. Short-Text Bypass Behavior
- **Q:** ≤200文字のテキストはNLTokenizerを通すか完全スキップか
- **A:** NLTokenizerを完全スキップ — 文字数チェックだけで即session.translate()へ

### 3. Whitespace & Separator Preservation
- **Q:** 改行や段落区切りの保持方法
- **A:** セパレーター記録方式を選択（ブロック→文の2段階分割より推奨）
- NLTokenizerのRange<String.Index>間のギャップ文字列を記録して結合時に復元

### 4. TextChunkerのコード配置
- **Q:** 新ファイルかTextNormalizationに追加か
- **A:** 新ファイル Transy/Translation/TextChunker.swift — 単一責任、テストしやすい

### 5. シマーとの統合
- **Q:** チャンク翻訳中のシマー表示方法
- **Discussion:** translate(batch:)のストリーミングプログレスも検討したが、translations(from:)の一括方式を選択
- **A:** シマーは現行のまま（全体にかかる）+ translations(from:)で一括翻訳
- **Deferred:** プログレス表示は将来のマイルストーンで検討

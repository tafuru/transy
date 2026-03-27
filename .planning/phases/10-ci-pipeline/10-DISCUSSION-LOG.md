# Phase 10: CI Pipeline - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2025-07-22
**Phase:** 10-ci-pipeline
**Areas discussed:** SwiftLint Configuration, SwiftFormat Configuration, CI Failure Policy

---

## SwiftLint Configuration

### Question 1: Rule strictness level

| Option | Description | Selected |
|--------|-------------|----------|
| 厳しめ (Strict) | Default + opt-in rules (`empty_count`, `first_where`, `modifier_order`), line length 150, SwiftUI-specific rules disabled | ✓ |
| デフォルトのみ | SwiftLint standard rules only, no customization | |
| 緩め | Default minus SwiftUI-incompatible rules (`trailing_comma`, `type_body_length`, `function_body_length`) | |

**User's choice:** 厳しめ（Recommended）— デフォルト+opt-inルール追加、ライン長150
**Notes:** None

### Question 2: Apply to existing code

| Option | Description | Selected |
|--------|-------------|----------|
| 既存コードも全てチェック | Check all code, fix warnings in initial PR | ✓ |
| 新規コードのみ | Exclude existing files, address gradually | |

**User's choice:** 既存コードも全てチェック — 初回は警告をまとめて修正
**Notes:** None

---

## SwiftFormat Configuration

### Question 3: Indent style

| Option | Description | Selected |
|--------|-------------|----------|
| 4スペース | Matches `project.yml` `indentWidth: 4` | ✓ |
| タブ | Xcode default | |
| 2スペース | Compact style | |

**User's choice:** インデント4スペース — project.ymlのindentWidth:4と一致
**Notes:** None

### Question 4: Conflict resolution with SwiftLint

| Option | Description | Selected |
|--------|-------------|----------|
| 競合ルールのみ無効化 | Disable `redundantSelf`, `trailingCommas`, etc. | ✓ |
| デフォルトそのまま | Use SwiftFormat defaults as-is | |
| おまかせ | Agent decides | |

**User's choice:** SwiftLintと競合するルールのみ無効化 — `redundantSelf`, `trailingCommas` 等
**Notes:** None

---

## CI Failure Policy

### Question 5: Required status checks

| Option | Description | Selected |
|--------|-------------|----------|
| 全ジョブ必須 | lint + build + test all required to merge | ✓ |
| lint任意 | Only build/test required, lint is advisory | |

**User's choice:** 全ジョブ必須 — lintもbuild/testも全てpass必須
**Notes:** None

### Question 6: Workflow trigger

| Option | Description | Selected |
|--------|-------------|----------|
| on: pull_request (mainのみ) | Only PRs targeting main | ✓ |
| on: pull_request + push (main) | PRs + direct pushes to main | |
| on: pull_request + push (全ブランチ) | All branches | |

**User's choice:** on: pull_request (main向けPRのみ)
**Notes:** Branch protection already blocks direct pushes to main

---

## Agent's Discretion

- Specific opt-in SwiftLint rules to add
- Additional SwiftFormat conflict rules to disable
- Whether to use `--strict` flag on SwiftLint

## Deferred Ideas

None

---
status: complete
phase: 04-settings
source: [04-01-SUMMARY.md, 04-02-SUMMARY.md]
started: 2026-03-15T14:30:00Z
updated: 2026-03-15T14:53:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Settings Window Surfacing
expected: Open "Settings…" from the Transy menu bar. A single native Settings window appears. No Dock icon appears. No duplicate windows on repeated open.
result: pass

### 2. Target Language Picker Default
expected: On first launch (after `defaults delete com.tafuru.transy targetLanguage`), the Settings picker shows your OS preferred language (English) pre-selected — not blank, not Arabic.
result: pass

### 3. Language Selection & Persistence
expected: Choose a different target language (e.g. Japanese) in the picker. Quit Transy, relaunch, reopen Settings. The picker still shows Japanese.
result: pass

### 4. Request Snapshot Isolation
expected: Trigger a translation (double Cmd+C on selected text). While the popup is visible, change the target language in Settings. The visible popup does NOT change. Dismiss, trigger again — the new popup uses the updated target language.
result: pass

### 5. No Guidance Before Relevance
expected: On a fresh state (no missing-model events recorded), open Settings. Only the Target Language picker is visible — no "Translation Model Required" guidance section.
result: pass

### 6. Generic Guidance After Missing Model
expected: Trigger a translation that results in a missing-model error (popup shows model-not-available message). Then reopen Settings. A guidance section appears: "Translation Model Required" header, copy mentioning "System Settings → General → Language & Region → Translation Languages", and an "Open Language & Region" button.
result: pass

### 7. System Settings Deep Link
expected: With guidance visible, click "Open Language & Region". System Settings opens directly to the General → Language & Region pane (not an unrelated last-viewed pane).
result: pass

### 8. Compact Layout
expected: Settings window is compact by default (just the picker). When guidance appears, the window grows modestly to accommodate it — no separate window, no excessive whitespace.
result: pass

## Summary

total: 8
passed: 8
issues: 0
pending: 0
skipped: 0

## Gaps

[none]

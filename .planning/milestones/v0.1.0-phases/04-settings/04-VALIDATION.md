---
phase: 04
slug: settings
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-03-15
---

# Phase 04 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Swift Testing (existing `TransyTests` target) |
| **Config file** | None — driven by the Xcode scheme via `xcodebuild test` |
| **Quick run command** | `xcodebuild test -scheme Transy -destination 'platform=macOS' -only-testing:TransyTests` |
| **Full suite command** | `xcodebuild test -scheme Transy -destination 'platform=macOS'` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `xcodebuild test -scheme Transy -destination 'platform=macOS' -only-testing:TransyTests`
- **After every plan wave:** Run `xcodebuild test -scheme Transy -destination 'platform=macOS'`
- **Before `/gsd-verify-work`:** Full suite must be green and the Phase 4 settings/manual checklist must pass
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 04-01-settings-store | 01 | 1 | APP-02 | unit | `xcodebuild test -scheme Transy -destination 'platform=macOS' -only-testing:TransyTests/SettingsStoreTests` | ❌ W0 | ⬜ pending |
| 04-01-target-snapshot | 01 | 1 | APP-02 | unit | `xcodebuild test -scheme Transy -destination 'platform=macOS' -only-testing:TransyTests/TargetLanguageSnapshotTests` | ❌ W0 | ⬜ pending |
| 04-02-guidance-state | 02 | 2 | APP-03 | unit | `xcodebuild test -scheme Transy -destination 'platform=macOS' -only-testing:TransyTests/TranslationModelGuidanceTests` | ❌ W0 | ⬜ pending |
| 04-02-settings-window | 02 | 2 | APP-02, APP-03 | build+manual | `xcodebuild test -scheme Transy -destination 'platform=macOS' -only-testing:TransyTests` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `TransyTests/SettingsStoreTests.swift` — covers first-run default resolution from OS preferred language, persistence to `UserDefaults`, and “stored value wins over later OS changes”
- [ ] `TransyTests/TargetLanguageSnapshotTests.swift` — covers “next translation uses new target language” while an already-started popup/request keeps its frozen target
- [ ] `TransyTests/TranslationModelGuidanceTests.swift` — covers no-guidance before relevance, generic guidance after a real missing-model event with unknown pair certainty, and optional pair-specific guidance only when trusted known-pair context exists
- [ ] Small guidance-state seam / helper — lets tests evaluate settings guidance without depending on live Apple model assets or UI timing

*Existing Swift Testing infrastructure already exists from earlier phases. Only phase-specific test files and a small guidance-state seam need to be added.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Settings opens from the menu bar as a native settings window without activating Dock-style app behavior | APP-02 | LSUIElement activation/window surfacing behavior must be validated on-device | Open `Settings…` from the menu bar and confirm the window appears above the current app without a Dock icon or regular app activation behavior |
| Selecting a target language in Settings persists across relaunch | APP-02 | Full launch/relaunch persistence is best confirmed end-to-end | Choose a non-default target language, quit/relaunch Transy, reopen Settings, and confirm the same language remains selected |
| A changed target language applies to the next translation request but does not mutate an already visible popup | APP-02 | Requires live coordination between Settings and the popup lifecycle | Start one translation, change the target language while the popup is visible, confirm the current popup does not change mid-flight, then trigger again and confirm the new request uses the new target |
| Settings stays compact by default and only grows modestly when guidance becomes relevant | APP-02, APP-03 | Visual density and resizing quality are UX judgments best checked live | Open Settings with no known missing-model state and confirm the window is compact; then enter a state that should show guidance and confirm the same window expands modestly instead of switching surfaces |
| Settings shows no model guidance before any real missing-model-relevant runtime state exists | APP-03 | The “only when relevant” rule is a UX truth best checked end-to-end | On a fresh/source-unknown state, open Settings and confirm no extra model-guidance row is shown yet |
| After a real translation reveals `Translation model not installed.`, Settings later shows short generic guidance with one clear System Settings action | APP-03 | Requires real Translation framework availability outcomes and end-to-end state propagation | Trigger a translation that yields the Phase 3 missing-model error, then reopen Settings and confirm a short generic guidance message appears with one clear action to the Apple Settings path rather than guessed pair-specific copy |
| Pair-specific guidance only appears when trusted known-pair context truly exists | APP-03 | Pair-specific copy is conditional and should not be guessed from uncertain runtime state | Cover this primarily with unit tests; only perform a live check if implementation exposes a trustworthy known-pair state during manual testing |
| The System Settings guidance action opens the expected Apple settings destination (or at minimum the correct System Settings area) without noisy extra automation prompts | APP-03 | The final deep-link / open behavior depends on macOS runtime behavior | Use the Settings guidance action on macOS 15 and confirm it opens the relevant System Settings area for Translation Languages without unexpected Apple Events prompts |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

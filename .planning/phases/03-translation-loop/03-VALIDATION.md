---
phase: 03
slug: translation-loop
status: ready
nyquist_compliant: true
wave_0_complete: false
created: 2026-03-14
---

# Phase 03 — Validation Strategy

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
- **Before `/gsd-verify-work`:** Full suite must be green and the live translation smoke checklist must pass
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 03-01-availability-preflight | 01 | 1 | TRAN-02 | unit | `xcodebuild test -scheme Transy -destination 'platform=macOS' -only-testing:TransyTests/TranslationAvailabilityClientTests` | ❌ W0 | ⬜ pending |
| 03-01-translation-runner | 01 | 1 | TRAN-01 | unit | `xcodebuild test -scheme Transy -destination 'platform=macOS' -only-testing:TransyTests/TranslationCoordinatorTests` | ❌ W0 | ⬜ pending |
| 03-02-translation-coordinator | 02 | 2 | TRAN-03 | unit | `xcodebuild test -scheme Transy -destination 'platform=macOS' -only-testing:TransyTests/TranslationRaceGuardTests` | ❌ W0 | ⬜ pending |
| 03-02-popup-state-wiring | 02 | 2 | TRAN-01, TRAN-02, TRAN-03 | build+manual | `xcodebuild test -scheme Transy -destination 'platform=macOS' -only-testing:TransyTests` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `TransyTests/TranslationAvailabilityClientTests.swift` — covers `.installed`, `.supported`, `.unsupported`, and ambiguous-source preflight mapping for TRAN-02
- [ ] `TransyTests/TranslationCoordinatorTests.swift` — covers `.loading → .result`, `.loading → .error`, and dismiss reset behavior for TRAN-01 / TRAN-03
- [ ] `TransyTests/TranslationRaceGuardTests.swift` — covers stale-success / stale-error suppression when request IDs change for TRAN-03
- [ ] Fake translation runner seam for tests — lets unit tests simulate success/failure without requiring Apple language assets in CI

*Existing Swift Testing infrastructure already exists from Phases 1-2. Only phase-specific test files and a fake translation seam need to be added.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Installed language pair replaces muted source text with translated output in the same popup | TRAN-01, TRAN-03 | Requires live Apple Translation assets and runtime framework behavior | On a macOS 15 machine with a supported installed pair, select Japanese text, press `Cmd+C` twice, and confirm the popup changes from muted source text to English result without opening another surface |
| Source language is auto-detected with no manual source-language picker | TRAN-02 | Framework UI behavior must be validated on-device | Trigger translation with ordinary Japanese text and confirm no source-language chooser or other Apple-provided prompt appears |
| Ambiguous or very short input stays inline and does not trigger a chooser UI | TRAN-02 | Apple Translation ambiguity behavior must be checked on a live machine | Trigger translation with deliberately short or ambiguous text and confirm no chooser/system prompt appears; the popup should stay visible with short inline copy such as `Couldn't detect the source language.` |
| Missing or uninstalled model shows a short inline error instead of framework download UI | TRAN-01, TRAN-03 | Requires live model state that tests cannot reliably control | Use text for an unsupported or not-yet-installed pair, trigger translation, and confirm the popup stays visible with a short inline error such as model unavailable rather than opening download/settings UI |
| Dismissing the popup cancels in-flight translation and does not reopen later | TRAN-03 | Requires live timing with the real popup/session lifecycle | Trigger translation on longer text, dismiss the popup before completion, and confirm no late result reopens or mutates the dismissed popup |
| Re-trigger while a translation is pending keeps the same popup and only the newest request wins | TRAN-03 | Real user pacing is needed to confirm the UX remains stable | Trigger translation, immediately trigger again on different source text, and confirm the popup stays in place, switches to the new source text, and never flashes the stale older result |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

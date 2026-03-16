---
phase: 02
slug: trigger-popup
status: ready
nyquist_compliant: true
wave_0_complete: false
created: 2026-03-14
---

# Phase 02 — Validation Strategy

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
- **Before `/gsd-verify-work`:** Full suite must be green and the manual popup/permission checklist must pass
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 02-01-permission-guidance | 01 | 1 | TRIG-02 | build+manual | `xcodebuild test -scheme Transy -destination 'platform=macOS' -only-testing:TransyTests` | ❌ W0 | ⬜ pending |
| 02-02-double-press-detector | 02 | 1 | TRIG-01 | unit | `xcodebuild test -scheme Transy -destination 'platform=macOS' -only-testing:TransyTests/DoublePressDetectorTests` | ❌ W0 | ⬜ pending |
| 02-02-hotkey-monitor | 02 | 1 | TRIG-01 | unit | `xcodebuild test -scheme Transy -destination 'platform=macOS' -only-testing:TransyTests/HotkeyMonitorTests` | ❌ W0 | ⬜ pending |
| 02-02-clipboard-manager | 02 | 1 | TRIG-03 | unit | `xcodebuild test -scheme Transy -destination 'platform=macOS' -only-testing:TransyTests/ClipboardManagerTests` | ❌ W0 | ⬜ pending |
| 02-03-popup-show | 03 | 2 | POP-01, POP-02 | build+manual | `xcodebuild test -scheme Transy -destination 'platform=macOS' -only-testing:TransyTests` | ❌ W0 | ⬜ pending |
| 02-03-popup-dismissal | 03 | 2 | POP-03 | build+manual | `xcodebuild test -scheme Transy -destination 'platform=macOS' -only-testing:TransyTests` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `TransyTests/DoublePressDetectorTests.swift` — covers timing logic, threshold reset, and triple-press behavior for TRIG-01
- [ ] `TransyTests/HotkeyMonitorTests.swift` — covers exact modifier matching, repeat filtering, and Cmd+C detection rules for TRIG-01
- [ ] `TransyTests/ClipboardManagerTests.swift` — covers save/restore round-trip behavior for TRIG-03

*Existing Swift Testing infrastructure already exists from Phase 1. Only the phase-specific test files need to be added.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Permission guidance appears when monitoring permission is missing | TRIG-02 | Requires live Accessibility permission state in macOS System Settings | Remove Accessibility permission if granted, launch Transy, open the menu bar menu, and confirm the guidance window appears with short instructions |
| Granting Accessibility permission enables monitoring without relaunch | TRIG-02 | Requires live System Settings interaction and runtime permission change | With Transy still running and guidance already shown, grant Accessibility access in System Settings, return to the app, wait a couple of seconds, then confirm `Cmd+C` twice now opens the popup without quitting/relaunching |
| Popup appears without stealing focus from the source app | POP-01 | Requires live interaction between Transy and another foreground app | In TextEdit or another app, select text and press `Cmd+C` twice, confirm popup appears while the source app remains active |
| Popup shows source text immediately in muted style | POP-02 | Visual presentation must be checked by a human | Trigger the popup and confirm source text appears right away in a readable muted/loading treatment |
| Escape dismisses popup | POP-03 | Popup keyboard dismissal depends on live event handling | Trigger the popup, press `Escape`, and confirm it disappears |
| Clicking outside dismisses popup | POP-03 | Requires real pointer interaction and outside-hit testing | Trigger the popup, click elsewhere on the screen, and confirm it disappears |
| Clipboard contents are restored after capture | TRIG-03 | End-to-end behavior spans trigger, pasteboard timing, and dismissal | Copy known clipboard content, trigger Transy on another text selection, dismiss popup, and confirm the original clipboard content is still present |
| Active-screen top-center placement is respected | POP-01 | Multi-display behavior depends on runtime screen state | On a multi-display setup, trigger from each display and confirm the popup appears near the top-center of the screen in active use |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

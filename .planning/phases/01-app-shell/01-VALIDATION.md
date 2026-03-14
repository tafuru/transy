---
phase: 01
slug: app-shell
status: ready
nyquist_compliant: true
wave_0_complete: false
created: 2026-03-14
---

# Phase 01 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (standard Xcode test target) |
| **Config file** | None needed — created by the Xcode project scaffold |
| **Quick run command** | `xcodebuild build -scheme Transy -destination 'platform=macOS'` |
| **Full suite command** | `xcodebuild test -scheme Transy -destination 'platform=macOS'` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `xcodebuild build -scheme Transy -destination 'platform=macOS'`
- **After every plan wave:** Run `xcodebuild test -scheme Transy -destination 'platform=macOS'` plus the manual smoke checklist below
- **Before `/gsd-verify-work`:** Full suite must be green and all manual shell checks must pass
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 01-01-scaffold | 01 | 1 | APP-01 | build | `xcodebuild build -scheme Transy -destination 'platform=macOS'` | ❌ W0 | ⬜ pending |
| 01-01-test-targets | 01 | 1 | APP-01 | test-infra | `xcodebuild test -scheme Transy -destination 'platform=macOS'` | ❌ W0 | ⬜ pending |
| 01-02-menu-shell | 02 | 2 | APP-01 | manual-ui | Build command + runtime smoke checks | ❌ W0 | ⬜ pending |
| 01-02-settings-entry | 02 | 2 | APP-01 | manual-ui | Build command + settings smoke checks | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `TransyTests/TransyTests.swift` — XCTest target stub to make `xcodebuild test` viable
- [ ] `TransyUITests/TransyUITests.swift` — UI test target stub for later popup/settings flows
- [ ] Xcode project, shared scheme, and test targets created as part of Plan 01-01

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Menu bar icon appears after launch | APP-01 | Requires a running LSUIElement app in the macOS menu bar | Launch Transy and confirm the icon is visible in the menu bar |
| No Dock icon on launch | APP-01 | Dock presence is an OS-level runtime behavior | Launch Transy and confirm nothing appears in the Dock or Cmd+Tab switcher |
| Menu shows only `Settings…` and `Quit` | APP-01 | Requires clicking the live menu bar item | Click the icon and confirm the menu is minimal with only the expected entries |
| `Settings…` opens a placeholder settings window | APP-01 | Requires scene/window behavior validation | Click `Settings…` and confirm a minimal settings-style window opens |
| No Dock icon while Settings is open | APP-01 | Activation-policy behavior must be validated at runtime | Open `Settings…`, keep it visible, and confirm the Dock remains empty |
| `Quit` exits the app cleanly | APP-01 | Process exit is an end-to-end behavior | Click `Quit` and confirm the menu bar item disappears and the process exits |
| No entitlement or sandbox errors on launch | APP-01 | Needs runtime inspection in Console.app | Launch Transy, inspect Console.app for launch-time entitlement/sandbox violations, and confirm none are present |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

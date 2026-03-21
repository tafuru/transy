---
phase: 06
slug: popup-positioning
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-20
---

# Phase 06 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Swift Testing (`import Testing`, `@Suite`, `@Test`, `#expect`) |
| **Config file** | Transy.xcodeproj (generated from project.yml via xcodegen) |
| **Quick run command** | `xcodebuild test -project Transy.xcodeproj -scheme Transy -destination 'platform=macOS' -only-testing:TransyTests 2>&1 \| tail -5` |
| **Full suite command** | `xcodebuild test -project Transy.xcodeproj -scheme Transy -destination 'platform=macOS' -quiet` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick run command
- **After every plan wave:** Run full suite command
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 06-00-01 | 00 | 0 | POP-06, POP-07 | unit | `xcodebuild test -only-testing:TransyTests` | ❌ W0 | ⬜ pending |
| 06-01-01 | 01 | 1 | POP-06 | unit+manual | `xcodebuild test -only-testing:TransyTests` | ❌ W0 | ⬜ pending |
| 06-01-02 | 01 | 1 | POP-07 | unit+manual | `xcodebuild test -only-testing:TransyTests` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `TransyTests/PopupPositioningTests.swift` — unit tests for positioning math (cursor-relative placement, edge-clamping, flip logic)
- [ ] Tests verify pure positioning functions independent of NSPanel/NSScreen

*Positioning math is pure geometry — fully automatable with unit tests.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Popup appears near cursor visually | POP-06 | Requires visual confirmation of NSPanel position relative to actual cursor | Trigger translation at various cursor positions, verify popup appears ~8pt below cursor |
| Popup stays on-screen at edges | POP-07 | Screen edge behavior requires real screen geometry | Move cursor to all 4 screen edges, trigger translation, verify popup stays fully visible |
| Popup flips above cursor at bottom edge | POP-07 | Visual flip verification | Trigger translation with cursor near bottom edge, verify popup appears above cursor |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

---
phase: 08
slug: first-launch-onboarding
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-23
---

# Phase 08 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Swift Testing (import Testing, @Suite, @Test, #expect) |
| **Config file** | TransyTests/ directory |
| **Quick run command** | `xcodebuild test -scheme Transy -destination 'platform=macOS' -only-testing TransyTests 2>&1 \| tail -5` |
| **Full suite command** | `xcodebuild test -scheme Transy -destination 'platform=macOS' 2>&1 \| tail -20` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick test command
- **After every plan wave:** Run full suite command
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 08-01-01 | 01 | 1 | OBD-01 | manual | Build + launch without AX | N/A | ⬜ pending |
| 08-01-02 | 01 | 1 | OBD-02 | manual | Verify GuidanceView content | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. Phase 8 changes are primarily behavioral (launch-time AX check and view content) — verified manually and via existing build.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Guidance window shows on first launch without AX | OBD-01 | Requires AX permission state manipulation in System Settings | 1. Revoke AX for Transy in System Settings 2. Launch app 3. Verify guidance window appears immediately |
| Guidance window does NOT show when AX is granted | OBD-01 | Requires AX permission state | 1. Grant AX for Transy 2. Launch app 3. Verify no guidance window |
| "Why permission is needed" text is visible | OBD-02 | UI content verification | 1. Revoke AX 2. Launch app 3. Verify explanation text is present |
| "Open System Settings" button works | OBD-02 | System Settings integration | 1. Click button 2. Verify System Settings opens to Accessibility pane |
| Window auto-closes after permission grant | OBD-01 | Requires real-time permission toggle | 1. Show guidance 2. Grant AX in System Settings 3. Verify window closes within ~2 seconds |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

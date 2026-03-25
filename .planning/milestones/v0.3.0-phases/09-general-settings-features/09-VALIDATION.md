---
phase: 09
slug: general-settings-features
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-23
---

# Phase 09 — Validation Strategy

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
| 09-01-01 | 01 | 1 | SET-03 | manual | Build + toggle in Settings | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. Phase 9 adds a UI toggle backed by SMAppService — verified manually and via build.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Launch at Login toggle visible in General section | SET-03 | UI verification | 1. Open Settings 2. Verify General section has "Launch at Login" toggle |
| Toggle ON registers app for login | SET-03 | Requires system login item state | 1. Toggle ON 2. Check System Settings → General → Login Items → Transy listed |
| Toggle OFF unregisters app from login | SET-03 | Requires system login item state | 1. Toggle OFF 2. Check System Settings → Login Items → Transy removed |
| Toggle reflects system state | SET-03 | Requires System Settings cross-check | 1. Toggle ON via app 2. Disable in System Settings 3. Reopen Settings → toggle should be OFF |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

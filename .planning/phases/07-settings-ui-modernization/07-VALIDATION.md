---
phase: 07
slug: settings-ui-modernization
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-03-21
---

# Phase 07 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Swift Testing (`import Testing`, `@Suite`, `@Test`, `#expect`) |
| **Config file** | Transy.xcodeproj (generated via xcodegen from project.yml) |
| **Quick run command** | `xcodebuild test -scheme Transy -destination 'platform=macOS' -quiet` |
| **Full suite command** | `xcodebuild test -scheme Transy -destination 'platform=macOS'` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `xcodebuild test -scheme Transy -destination 'platform=macOS' -quiet`
- **After every plan wave:** Run `xcodebuild test -scheme Transy -destination 'platform=macOS'`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 07-00-01 | 00 | 1 | SET-01, SET-02 | build + manual | `xcodebuild build` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. Phase 7 is primarily a UI restructure — existing tests must continue to pass (no regressions). No new test files needed for layout restructuring.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| TabView renders General and About tabs | SET-01 | Visual UI layout verification | Open Settings, verify 2 tabs visible, switch between them |
| Sections render with bordered groups | SET-02 | Visual styling verification | Open Settings → General, verify Translation section has System Settings-style bordered container |
| About tab shows app info + GitHub link | SET-01 | Content and link verification | Open Settings → About, verify name/version/description/link present |
| Existing language picker works in new layout | SET-02 | Functional regression check | Open Settings → General, change target language, verify it persists |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-03-21

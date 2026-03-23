---
phase: 08-first-launch-onboarding
verified: 2026-03-23T13:21:00Z
status: human_needed
score: 5/5 must-haves verified
human_verification:
  - test: "Revoke AX permission → launch Transy → guidance window appears immediately"
    expected: "Guidance window with title, WHY explanation, instruction, and Open System Settings button is visible on launch"
    why_human: "Requires toggling real AX permission state in macOS System Settings; cannot simulate programmatically"
  - test: "Grant AX permission → launch Transy → no guidance window"
    expected: "App launches silently to menu bar, no windows appear"
    why_human: "Requires AX to be already granted in System Settings"
  - test: "Click Open System Settings button in guidance window"
    expected: "System Settings opens directly to Privacy & Security → Accessibility pane"
    why_human: "Requires real macOS System Settings interaction to verify deep link"
  - test: "With guidance window open, grant AX in System Settings"
    expected: "Guidance window auto-closes within ~2 seconds, hotkey monitoring starts"
    why_human: "Requires real-time permission toggle and observing window dismiss behavior"
---

# Phase 8: First-Launch Onboarding Verification Report

**Phase Goal:** New users receive Accessibility permission guidance automatically without needing to discover it
**Verified:** 2026-03-23T13:21:00Z
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | User launching Transy without AX permission sees guidance window immediately on app start | ✓ VERIFIED | `AppDelegate.swift:28` calls `GuidanceWindowController.shared.showIfNeeded()` in `applicationDidFinishLaunching` before `startMonitoringIfNeeded()` |
| 2 | Guidance window explains WHY Accessibility access is needed, not just that it is required | ✓ VERIFIED | `GuidanceView.swift:9` contains "Transy uses Accessibility access to detect the double ⌘C shortcut that triggers translations" |
| 3 | User can click a button to open System Settings directly to the Accessibility pane | ✓ VERIFIED | `GuidanceView.swift:17-20` — Button("Open System Settings") with `guard let url = URL(string: "x-apple.systempreferences:...")` and `NSWorkspace.shared.open(url)` |
| 4 | User who already has AX permission sees no guidance window on launch | ✓ VERIFIED | `GuidanceWindowController.swift:20` — `guard !AXIsProcessTrusted() else { return }` early-exits when trusted |
| 5 | Guidance window auto-closes when permission is granted (existing polling behavior preserved) | ✓ VERIFIED | `GuidanceWindowController.swift:39-51` — 2-second polling timer checks `AXIsProcessTrusted()`, invalidates timer, closes window, fires `onPermissionGranted` callback |

**Score:** 5/5 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `Transy/AppDelegate.swift` | Proactive AX check on launch; contains "showIfNeeded" | ✓ VERIFIED | Line 28: `GuidanceWindowController.shared.showIfNeeded()` present, called before `startMonitoringIfNeeded()` on line 30 |
| `Transy/Permissions/GuidanceView.swift` | Enhanced guidance content with WHY explanation; contains "detect the double" | ✓ VERIFIED | Line 9: "detect the double ⌘C shortcut" present; WHY text + instruction text + button all substantive |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `AppDelegate.swift` | `GuidanceWindowController.shared.showIfNeeded()` | Direct call in applicationDidFinishLaunching before startMonitoringIfNeeded | ✓ WIRED | Line 28 calls `showIfNeeded()`, line 30 calls `startMonitoringIfNeeded()` — correct order |
| `GuidanceView.swift` | System Settings Accessibility pane | `NSWorkspace.shared.open` with deep link URL | ✓ WIRED | Line 18-19: `guard let url = URL(string: "x-apple.systempreferences:...")` → `NSWorkspace.shared.open(url)` |
| `GuidanceWindowController.swift` | `GuidanceView` | NSHostingController rootView | ✓ WIRED | Line 23: `NSHostingController(rootView: GuidanceView())` embeds the SwiftUI view |
| `GuidanceWindowController.swift` | `AppDelegate.startMonitoringIfNeeded` | `onPermissionGranted` callback | ✓ WIRED | Line 48: `self?.onPermissionGranted?()` fires → AppDelegate line 23-25 assigns callback to call `startMonitoringIfNeeded()` |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| OBD-01 | 08-01-PLAN | User sees Accessibility permission guidance automatically on first launch without needing to open Settings | ✓ SATISFIED | `showIfNeeded()` called proactively in `applicationDidFinishLaunching` (Truth 1); guarded by `AXIsProcessTrusted()` (Truth 4); auto-closes on grant (Truth 5) |
| OBD-02 | 08-01-PLAN | User is guided through permission setup with clear instructions and a button to open System Settings | ✓ SATISFIED | WHY explanation text present (Truth 2); "Open System Settings → ..." instruction preserved; Button with safe URL deep link to Accessibility pane (Truth 3) |

No orphaned requirements — only OBD-01 and OBD-02 are mapped to Phase 8 in REQUIREMENTS.md, and both are claimed by plan 08-01.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| — | — | No anti-patterns detected | — | — |

Zero TODOs, FIXMEs, placeholders, empty implementations, or force-unwraps found in any phase-modified file. URL force-unwrap was explicitly replaced with `guard let` (safe pattern).

### Commits Verified

| Commit | Message | Status |
|--------|---------|--------|
| `0d5fff6` | feat(08-01): add proactive AX guidance check on launch | ✓ EXISTS |
| `6dd9099` | feat(08-01): enhance GuidanceView with why explanation and safe URL | ✓ EXISTS |

### Human Verification Required

### 1. Guidance Window Appears Without AX Permission

**Test:** Revoke Accessibility permission for Transy in System Settings → Privacy & Security → Accessibility. Launch Transy.
**Expected:** Guidance window appears immediately with title "Accessibility Access Required", WHY explanation, instructions, and "Open System Settings" button.
**Why human:** Requires manipulating real AX permission state in macOS System Settings; cannot simulate programmatically.

### 2. No Guidance Window With AX Permission

**Test:** Ensure AX permission is granted for Transy. Launch Transy.
**Expected:** App starts silently as a menu bar agent. No guidance window appears.
**Why human:** Requires AX to be already granted; behavior depends on real permission state.

### 3. Open System Settings Button Works

**Test:** With guidance window visible, click "Open System Settings" button.
**Expected:** System Settings opens directly to Privacy & Security → Accessibility pane.
**Why human:** Requires verifying macOS deep link `x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility` navigates correctly.

### 4. Auto-Close on Permission Grant

**Test:** With guidance window open, toggle AX permission ON for Transy in System Settings.
**Expected:** Guidance window closes automatically within ~2 seconds. Hotkey monitoring starts (double ⌘C triggers translation).
**Why human:** Requires real-time permission state change and observing window dismissal and subsequent hotkey functionality.

### Gaps Summary

No gaps found. All 5 observable truths are verified at the code level. All artifacts exist, are substantive (no stubs), and are fully wired. Both requirements (OBD-01, OBD-02) are satisfied. No anti-patterns detected.

The only remaining verification items are runtime behaviors that require human testing with real macOS Accessibility permission toggling. These cannot be verified through static code analysis.

---

_Verified: 2026-03-23T13:21:00Z_
_Verifier: Claude (gsd-verifier)_

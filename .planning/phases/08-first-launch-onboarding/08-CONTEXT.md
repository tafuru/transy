---
phase: 08
slug: first-launch-onboarding
status: locked
created: 2026-03-23
---

# Phase 08 — Context Decisions

> Decisions locked during `/gsd-discuss-phase 8`. Downstream agents (planner, executor) treat these as constraints.

---

## Area 1: Display Trigger Logic

**Decision:** Show guidance automatically at app launch if `AXIsProcessTrusted()` returns false. No UserDefaults flag needed.

**Details:**
- Check AX permission status in `AppDelegate.applicationDidFinishLaunching`, before `startMonitoringIfNeeded()`
- If AX is already granted → skip guidance entirely, proceed normally
- If AX is NOT granted → show guidance window immediately
- This replaces the current "reactive" approach (only showing on failed hotkey trigger) with a "proactive" first-launch pattern
- No UserDefaults flag for "has launched before" — AX permission state is the sole determinant
- On every subsequent launch where AX is revoked, guidance will show again (desired behavior)

**Rationale:** Simplest possible logic. AX state is the ground truth — if permission is missing, user needs guidance regardless of whether it's their first or tenth launch.

---

## Area 2: Guidance Content

**Decision:** Reuse existing `GuidanceView` with an added explanation of WHY Accessibility permission is needed.

**Details:**
- Keep current structure: title + body text + "Open System Settings" button
- Add a brief explanation above or below the existing text: why Transy needs Accessibility access (to detect the global translation shortcut using a system-wide key event monitor)
- No app icon, no multi-step wizard, no separate welcome screen
- Single-page, single-purpose: explain need → provide action button
- Keep it minimal per Apple HIG onboarding guidelines

**Rationale:** Existing GuidanceView already has the right structure. Adding context ("why") improves user confidence without adding complexity.

---

## Area 3: Post-Permission Behavior

**Decision:** Immediately close the guidance window when permission is granted (current behavior unchanged).

**Details:**
- Existing 2-second polling timer in `GuidanceWindowController` detects permission grant
- Window closes automatically, `onPermissionGranted` callback fires
- No success message, no usage tutorial
- User is ready to use Transy — they already see the menu bar icon
- `startMonitoringIfNeeded()` will be called (or re-called) after permission is granted

**Rationale:** Minimal friction. User granted permission → app works. No additional steps needed.

---

## Code Context

### Reusable Assets
- `GuidanceWindowController.shared` — singleton with lazy NSWindow creation, permission polling, callback mechanism
- `GuidanceView` — SwiftUI view with title, explanation, System Settings button
- `AXIsProcessTrusted()` — Foundation function for permission check
- URL scheme `x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility` — proven working

### Integration Points
- `AppDelegate.applicationDidFinishLaunching` — add AX check before `startMonitoringIfNeeded()`
- `GuidanceWindowController.showIfNeeded()` — already guards against showing when trusted
- `onPermissionGranted` callback — already chains to `startMonitoringIfNeeded()`

### Current Flow (to be modified)
```
AppDelegate.applicationDidFinishLaunching:
  1. Set activation policy
  2. Register onPermissionGranted callback
  3. startMonitoringIfNeeded()  ← hotkey monitor starts
  4. (Guidance shows ONLY if user triggers hotkey without permission)
```

### Target Flow (Phase 8)
```
AppDelegate.applicationDidFinishLaunching:
  1. Set activation policy
  2. Register onPermissionGranted callback
  3. if !AXIsProcessTrusted() → show guidance immediately
  4. startMonitoringIfNeeded()  ← still called (hotkey will work once permission granted)
```

---

## Deferred Ideas

None.

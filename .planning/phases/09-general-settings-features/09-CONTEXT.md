---
phase: 09
slug: general-settings-features
status: locked
created: 2026-03-23
---

# Phase 09 — Context Decisions

> Decisions locked during `/gsd-discuss-phase 9`. Downstream agents (planner, executor) treat these as constraints.

---

## Scope Change

**SET-04 (Auto-Dismiss) has been removed from this phase by user decision.** Phase 9 now contains only SET-03 (Launch at Login). SET-04 is deferred to Future Requirements.

---

## Area 1: Launch at Login Implementation

**Decision:** Use `SMAppService.mainApp` from ServiceManagement framework. Default OFF.

**Details:**
- Use `SMAppService.mainApp.register()` / `unregister()` for toggling
- Default state: OFF (user explicitly enables)
- Source of truth: `SMAppService.mainApp.status` (not UserDefaults) — reflects actual system state, including changes made in System Settings
- Error handling: Silent — if register/unregister fails, the toggle simply reflects the actual state (no alerts)
- ServiceManagement framework must be added to project.yml dependencies
- macOS 15+ deployment target ensures SMAppService is available

**Rationale:** SMAppService.mainApp is the modern, recommended way to handle launch-at-login on macOS 13+. Using `.status` as source of truth avoids state desync if user changes login items in System Settings.

---

## Area 2: Settings UI Layout

**Decision:** Add a new "General" Section above the existing "Translation" Section in GeneralSettingsView.

**Details:**
- New `Section("General")` containing the Launch at Login toggle
- Existing `Section("Translation")` remains unchanged below
- Both sections within the existing `Form` with `.formStyle(.grouped)` — maintains bordered macOS styling
- Toggle uses SwiftUI `Toggle` control with label "Launch at Login"
- Toggle binding reads from `SMAppService.mainApp.status` and calls register/unregister on change

**Rationale:** Launch at Login is an app-level setting, not a translation setting. Separate sections maintain clear logical grouping per macOS HIG conventions.

---

## Code Context

### Reusable Assets
- `GeneralSettingsView.swift` — Existing Form/Section pattern with `.formStyle(.grouped)`
- `SettingsStore.swift` — UserDefaults persistence pattern (not needed for SMAppService, but available if needed)
- `project.yml` — xcodegen config, needs ServiceManagement framework added

### Integration Points
- `GeneralSettingsView.swift` — Add new Section("General") with Toggle
- `project.yml` — Add `ServiceManagement` to framework dependencies
- No changes needed in AppDelegate, PopupController, or PopupView

### SMAppService Pattern
```swift
import ServiceManagement

// Check status
let isEnabled = SMAppService.mainApp.status == .enabled

// Register
try? SMAppService.mainApp.register()

// Unregister
try? SMAppService.mainApp.unregister()
```

---

## Deferred Ideas

- **SET-04 (Auto-Dismiss):** Popup auto-dismiss with configurable duration — removed from v0.3.0 scope by user decision. Move to Future Requirements.

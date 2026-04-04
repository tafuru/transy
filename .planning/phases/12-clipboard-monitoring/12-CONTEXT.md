# Phase 12: Clipboard Monitoring - Context

**Gathered:** 2026-03-31
**Status:** Ready for planning

<domain>
## Phase Boundary

Replace the existing Double ⌘C (Accessibility permission-based) trigger with a permission-free clipboard monitoring approach. NSPasteboard.general.changeCount is polled on a timer to detect new text, which is then sent through the existing translation pipeline. The Double ⌘C mechanism and all Accessibility permission code are removed.

</domain>

<decisions>
## Implementation Decisions

### Polling Strategy
- **D-01:** Poll NSPasteboard.general.changeCount every 500ms using Timer.scheduledTimer (RunLoop-based)
- **D-02:** Disable App Nap via NSProcessInfo.processInfo.beginActivity only while clipboard monitoring is active
- **D-03:** Clipboard monitoring is enabled by default on app launch — no user action required

### Trigger Mode (BREAKING CHANGE)
- **D-04:** Double ⌘C trigger mode is **removed entirely** — clipboard monitoring is the only trigger mode
- **D-05:** Accessibility permission is no longer required — remove all AXIsProcessTrusted checks and guidance UI
- **D-06:** Remove HotkeyMonitor, DoublePressDetector, GuidanceView, GuidanceWindowController, and related AX permission code
- **D-07:** Remove corresponding tests (DoublePressDetectorTests)

### Content Filtering
- **D-08:** Only trigger translation when .string type is present AND no concealed pasteboard types exist (password manager protection)
- **D-09:** No minimum text length — even 1 character triggers translation
- **D-10:** Skip re-translation if the clipboard text is identical to the previous trigger text (duplicate suppression)

### Self-Write Prevention
- **D-11:** After Transy writes to the clipboard (restore), record the resulting changeCount. When the polling timer fires and changeCount matches the recorded value, skip processing.

### Agent's Discretion
- Timer lifecycle management (start/stop with app lifecycle)
- Exact implementation of concealed type detection
- How to integrate with existing ClipboardManager and translation pipeline

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Existing Trigger Architecture
- `Transy/Trigger/HotkeyMonitor.swift` — Current trigger implementation (to be removed)
- `Transy/Trigger/DoublePressDetector.swift` — Current double-press logic (to be removed)
- `Transy/Trigger/ClipboardManager.swift` — Clipboard read/save/restore (to be retained and extended)
- `Transy/Trigger/ClipboardRestoreSession.swift` — Restore session management (evaluate for retention)

### App Integration
- `Transy/AppDelegate.swift` — Main trigger flow orchestration (handleTrigger must be refactored)
- `Transy/Settings/SettingsStore.swift` — Settings persistence (no trigger mode setting needed now)
- `Transy/Settings/GeneralSettingsView.swift` — Settings UI (remove trigger mode picker if planned)

### Permissions (to be removed)
- `Transy/Permissions/GuidanceView.swift` — AX permission guidance (to be removed)
- `Transy/Permissions/GuidanceWindowController.swift` — AX permission window controller (to be removed)

### Requirements
- `.planning/REQUIREMENTS.md` — CLB-01 through CLB-04

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ClipboardManager`: Already handles clipboard read/save/restore — extend with changeCount tracking
- `TranslationCoordinator`: Existing translation pipeline — unchanged, clipboard monitor feeds text into it
- `PopupController`: Existing popup display — unchanged
- `SettingsStore`: Observable store with UserDefaults — can store monitoring preferences

### Established Patterns
- @MainActor for all UI/clipboard operations
- Observable macro for reactive settings
- Task-based async flow in AppDelegate.handleTrigger

### Integration Points
- `AppDelegate.applicationDidFinishLaunching` — Start clipboard monitor instead of HotkeyMonitor
- `AppDelegate.handleTrigger` — Refactor to accept text directly (no more preSnapshot)
- `ClipboardRestoreSession` — May be simplified since there's no "pre-capture snapshot" concept with polling

</code_context>

<specifics>
## Specific Ideas

- Double ⌘C is being removed because it requires Accessibility permission which creates friction
- The app should "just work" from install — no permission dialogs, no setup
- Clipboard monitoring is simpler for users to understand (copy text → translation appears)

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

### Reviewed Todos (not folded)
- "Add translation model install guidance" — belongs to Phase 13 (Translation Download UI)
- "Track translation cancellation latency" — performance optimization, separate concern

</deferred>

---

*Phase: 12-clipboard-monitoring*
*Context gathered: 2026-03-31*

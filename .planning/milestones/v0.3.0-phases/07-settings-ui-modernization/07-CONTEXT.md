# Phase 7: Settings UI Modernization - Context

**Gathered:** 2026-03-21
**Status:** Ready for planning

<domain>
## Phase Boundary

Restructure the existing single-view SettingsView into a macOS-standard tabbed Settings window with properly grouped sections. No new settings features — Phase 9 handles Launch at Login and Auto-Dismiss.

</domain>

<decisions>
## Implementation Decisions

### Tab Structure
- SwiftUI `TabView` with top tabs (macOS standard style)
- Two tabs: **General** and **About**
- General tab holds existing Target Language picker and Model Guidance
- About tab is new — informational only

### About Tab Content
- App name (Transy)
- Version number (from Bundle)
- One-line description ("A lightweight macOS menu bar translator")
- GitHub repository link (https://github.com/tafuru/transy)

### Section Style
- Use SwiftUI `Form` + `Section` for System Settings-style bordered groups
- General tab: single "Translation" section containing Target Language picker + Model Guidance
- Phase 9 will add "General" and "Popup" sections to the General tab

### Claude's Discretion
- Tab icons (SF Symbols) — choose appropriate icons for General and About
- About tab layout and spacing — standard macOS About page feel
- Window size adjustments to fit new tabbed layout

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `SettingsView.swift` — Target Language picker and Model Guidance logic (to be restructured, not rewritten)
- `SettingsStore.swift` — @Observable store with UserDefaults persistence (unchanged)
- `SupportedLanguageOption` — Language loading and reconciliation logic (reusable as-is)
- `TranslationModelGuidance` — Guidance state machine (reusable as-is)

### Established Patterns
- Settings scene declared in `TransyApp.swift` via `Settings { SettingsView(...) }`
- `SettingsStore` injected as parameter, not environment object
- `openSystemSettings()` uses `x-apple.systempreferences:` URL scheme

### Integration Points
- `TransyApp.swift:13-15` — Settings scene wraps SettingsView; will wrap new tabbed container
- `SettingsStore` remains the single data source — no new persistence needed for Phase 7
- Phase 9 will add new @Observable properties to SettingsStore

</code_context>

<specifics>
## Specific Ideas

- User referenced "macOS System Settings style" grouped sections with bordered blocks
- Tabs should match native macOS app Settings conventions (like Xcode or other Apple apps)
- Keep it clean and minimal — not overloaded

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 07-settings-ui-modernization*
*Context gathered: 2026-03-21*

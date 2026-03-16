# Phase 1: App Shell - Context

**Gathered:** 2026-03-14
**Status:** Ready for planning

<domain>
## Phase Boundary

Build the first runnable Transy shell: a macOS menu bar resident with no Dock presence, a minimal menu accessible from the menu bar, a placeholder settings surface, and the initial project scaffold/configuration for macOS 15+. Trigger detection, permissions onboarding, popup translation UI, and real settings are separate phases.

</domain>

<decisions>
## Implementation Decisions

### Menu Bar Appearance
- Use an icon-only menu bar item in Phase 1.
- Keep the visual direction quiet and native-looking rather than branded or attention-seeking.
- Preserve a slight accent character only if it can be done without breaking standard macOS menu bar conventions.
- Keep the menu bar item visually static in Phase 1; do not add state-driven icon changes yet.

### Click Behavior
- Clicking the menu bar item opens a standard dropdown menu, not a custom popover shell.
- Keep the menu intentionally minimal in Phase 1.
- Do not add a header row or status row to the menu.
- Initial menu contents should be `Settings…` and `Quit` only.

### First Launch Experience
- On first launch, the app should start quietly in the menu bar.
- Do not show a welcome window, first-run popover, notification, or startup cue in Phase 1.
- If the user opens the menu during Phase 1, keep it clean; do not explain that later phases are still pending.
- The shell should feel invisible and ambient until real features arrive.

### Settings Entry
- Keep a visible `Settings…` entry in Phase 1.
- Selecting `Settings…` should open a minimal native-feeling settings-style window rather than a disabled or hidden command.
- The placeholder settings surface should contain only a title and a short note for now.
- The note should be quiet and matter-of-fact rather than playful or roadmap-heavy.

### Claude's Discretion
- Exact SF Symbol or icon treatment, as long as it stays icon-only, quiet, and native.
- Whether the accent preference is expressed now or deferred after validating what still looks correct in the macOS menu bar.
- Exact placeholder settings copy, spacing, and window size.
- Standard menu polish details such as separators, keyboard equivalents, and ordering conventions, as long as the menu remains minimal.

</decisions>

<specifics>
## Specific Ideas

- The shell should feel menu-bar-first and ambient rather than like a traditional app window.
- Minimalism matters more than early explanation.
- A placeholder settings surface is preferred over a disabled or missing `Settings…` command because it makes the shell feel complete from day one.

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- None yet — the repository currently contains planning docs and GSD workflow files, but no Swift source, Xcode project, asset catalog, or reusable UI components.

### Established Patterns
- Planning already locks the product direction: menu bar-only behavior, no Dock icon, macOS 15+ minimum, Apple Translation later, and an `NSPanel` popup in later phases.
- There are no existing code patterns to conform to yet, so Phase 1 will establish the initial project structure and app-shell conventions.

### Integration Points
- Phase 1 will create the first app entry point, menu bar item, menu actions, and app configuration files that later phases attach to.
- The placeholder `Settings…` action created here should become the stable entry point for the real settings window in Phase 4.
- The project scaffold should leave room for later trigger monitoring, popup presentation, and translation coordination without reworking the shell.

</code_context>

<deferred>
## Deferred Ideas

- Real target-language controls and model management belong to Phase 4.
- Trigger monitoring, permission guidance, and any first-run onboarding belong to Phase 2.
- Visual state changes in the menu bar item can be revisited after the app has meaningful states to represent.
- Auto-launch at login remains deferred to a future phase / v2.

</deferred>

---

*Phase: 01-app-shell*
*Context gathered: 2026-03-14*

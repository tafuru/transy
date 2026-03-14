# Phase 2: Trigger & Popup - Context

**Gathered:** 2026-03-14
**Status:** Ready for planning

<domain>
## Phase Boundary

Implement the selected-text trigger and popup shell for Transy: pressing `Command+C` twice should capture selected text, restore the previous clipboard contents, and show a non-focus-stealing popup with the source text in a muted loading-state style. This phase also includes user guidance when the required monitoring permissions are missing. Real translation output, near-selection popup positioning, and full settings behavior are separate phases.

</domain>

<decisions>
## Implementation Decisions

### Permission Guidance Flow
- Do not show permission guidance on first launch.
- Show permission guidance the first time a trigger attempt fails because the required monitoring permission is missing.
- Present the guidance as a small dedicated guidance window rather than an alert or menu popover.
- Keep the guidance copy short and matter-of-fact.
- If permissions are still missing, show the guidance window again on each failed trigger attempt rather than suppressing it after the first dismissal.

### Popup Placement
- Phase 2 uses a fixed placement rule; near-selection or near-cursor positioning is deferred.
- Show the popup on the active screen.
- Place it near the top-center of that screen.
- Use a subtle fade-in rather than a strong motion effect.
- If the trigger fires again in quick succession, reuse the same popup position and replace its contents instead of stacking multiple popups.

### Popup Visual Density
- Keep the popup as a compact card rather than a larger reading panel.
- Show the source text in a readable form with a subtle muted/loading treatment rather than a heavy skeleton effect.
- For longer text, show a few lines and then truncate rather than letting the popup grow aggressively.
- Keep the popup content-only in Phase 2: no Transy label, extra chrome, or additional loading indicator.

### Trigger Miss Feedback
- If the trigger fires but selected text cannot be captured, stay silent in Phase 2.
- Visible feedback should appear only when permission guidance is required.
- The trigger should feel invisible unless it actually succeeds.
- If permissions are fine but a single capture attempt fails, keep the app fully silent rather than showing a hint.

### Claude's Discretion
- Exact monitoring API choice, timing thresholds, repeat filtering, and clipboard-restore implementation details.
- Exact popup dimensions, typography, corner radius, and spacing as long as the popup stays compact and content-first.
- Exact wording of the permission guidance steps beyond the requested short, matter-of-fact tone.
- Exact screen insets, animation timing, and truncation thresholds as long as the popup remains top-center on the active screen.

</decisions>

<specifics>
## Specific Ideas

- The Phase 1 shell should remain quiet and ambient; Phase 2 should preserve that feel.
- The popup should feel like a lightweight reading aid, not a branded utility panel or notification clone.
- The user explicitly wants eventual placement near the selected text / mouse cursor, but that should be treated as a later UI refinement rather than Phase 2 scope.

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Transy/TransyApp.swift`: already hosts the menu bar app scene and remains the shell entry point for Phase 2 additions.
- `Transy/AppDelegate.swift`: already contains explicit Phase 2 hook comments for attaching the hotkey monitor and configuring the popup host.
- `Transy/AppState.swift`: already reserves Phase 2 concepts (`isPopupVisible`, `triggerMonitor`) and is the natural coordinator for trigger/popup state.
- `Transy/MenuBar/MenuBarView.swift`: provides the existing menu bar commands and should remain minimal while trigger/popup behavior is added elsewhere.

### Established Patterns
- The app is an `LSUIElement` menu bar agent with no Dock icon and `NSApp.setActivationPolicy(.accessory)`.
- `project.yml` managed by xcodegen is the source of truth for project configuration.
- App Sandbox is intentionally disabled, leaving future global monitoring options available.
- The app already uses a SwiftUI `Settings` scene and `NSApp.activate()` to surface windows correctly in an `LSUIElement` app.
- Phase 1 established a quiet, minimal, ambient UX direction that Phase 2 should preserve.

### Integration Points
- The trigger monitor and popup presenter should attach through `AppDelegate` / `AppState` instead of reshaping the menu bar shell.
- Permission guidance can be introduced as a separate small window without changing the existing menu structure.
- The Phase 2 popup should coexist with the existing menu bar app model and no-Dock behavior already verified in Phase 1.

</code_context>

<deferred>
## Deferred Ideas

- Positioning the popup near the selected text or mouse cursor belongs to a later UI refinement phase (`UI-01` in requirements).
- Showing translated output in the popup belongs to Phase 3.
- Real target-language controls and model-management UX belong to Phase 4.
- Any visible feedback for non-permission trigger misses remains deferred unless Phase 2 validation shows silence is too confusing.

</deferred>

---

*Phase: 02-trigger-popup*
*Context gathered: 2026-03-14*

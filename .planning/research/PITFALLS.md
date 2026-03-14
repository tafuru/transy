# Pitfalls Research

**Domain:** macOS menu bar selected-text translator (SwiftUI/AppKit, clipboard-based trigger, on-device translation)
**Researched:** 2026-03-14
**Confidence:** HIGH

---

## Critical Pitfalls

### Pitfall 1: Reading the Clipboard Too Early

**What goes wrong:**
The trigger fires before the source app has finished writing the copied selection to `NSPasteboard`, so Transy reads stale or empty content.

**How to avoid:**
- Validate a small delayed read in Phase 2 (for example, ~50–100 ms)
- Check pasteboard change state before consuming the content
- Fail visibly rather than translating the wrong string

**Phase to address:** Trigger & Popup

---

### Pitfall 2: Popup Steals Focus from the Source App

**What goes wrong:**
A normal window activates Transy and breaks the user's reading flow.

**How to avoid:**
- Use `NSPanel` with non-activating behavior
- Never design the popup around `WindowGroup` semantics
- Verify Escape / click-outside dismissal without making Transy the foreground app

**Phase to address:** Trigger & Popup

---

### Pitfall 3: Clipboard Contents Are Not Restored

**What goes wrong:**
The double-copy gesture overwrites the user's previous clipboard contents and leaves them lost after translation.

**How to avoid:**
- Snapshot the previous clipboard contents before capture
- Restore them after the source text has been safely read
- Treat clipboard preservation as a correctness requirement, not polish

**Phase to address:** Trigger & Popup

---

### Pitfall 4: Permission Requirements Are Assumed Too Early

**What goes wrong:**
The project hard-codes a single permission or capability story before validating the actual monitoring API that will be used in Phase 1.

**How to avoid:**
- Treat permission behavior as an early validation task, not a solved assumption
- Document the exact monitoring API and required user-facing guidance once validated
- Keep roadmap language generic until the Phase 1 spike confirms the implementation path

**Phase to address:** App Shell / Trigger & Popup

---

### Pitfall 5: Model Availability Is Treated as an Edge Case

**What goes wrong:**
Apple Translation may require system-managed model downloads for the chosen language pair. If the app assumes the model always exists, translation fails with a confusing experience.

**How to avoid:**
- Check model/language availability before or during translation requests
- Show clear guidance when a required model is missing
- Connect settings UI and runtime error handling to the same availability story

**Phase to address:** Translation Loop / Settings

---

### Pitfall 6: Translation Results Arrive Out of Order

**What goes wrong:**
The user triggers two translations quickly and an older request overwrites a newer one.

**How to avoid:**
- Use cancellation or request tokens in the coordinator
- Only apply results if they still match the latest request
- Keep popup state transitions centralized

**Phase to address:** Translation Loop

---

## Moderate Pitfalls

### Pitfall 7: Double-Press Window Feels Wrong

**What goes wrong:**
If the double-press threshold is too short, the gesture never triggers. If too long, normal copy workflows feel hijacked.

**How to avoid:**
- Start with a reasonable default
- Validate with real usage on a real keyboard
- Defer user configurability if needed, but design for it

### Pitfall 8: Popup Appears Off-Screen or Feels Detached

**What goes wrong:**
A fixed popup position may feel unnatural, and an unconstrained position may clip on multi-monitor setups or around the notch.

**How to avoid:**
- Clamp to visible screen bounds
- Validate whether fixed positioning is acceptable for v1
- Defer selection-relative positioning unless it becomes necessary

### Pitfall 9: LSUIElement / Activation Policy Is Misconfigured

**What goes wrong:**
The app unexpectedly shows a Dock icon or behaves like a regular app window because menu bar utility settings were configured in the wrong place.

**How to avoid:**
- Set `LSUIElement` in `Info.plist`
- Test settings-window opening behavior specifically
- Verify the app does not appear in Cmd+Tab if that is the intended utility behavior

---

## Phase Mapping Summary

| Pitfall | Phase |
|---------|-------|
| Clipboard timing | Trigger & Popup |
| Focus-stealing popup | Trigger & Popup |
| Clipboard restoration | Trigger & Popup |
| Permission ambiguity | App Shell / Trigger & Popup |
| Model availability | Translation Loop / Settings |
| Stale translation results | Translation Loop |
| Double-press threshold | Trigger & Popup / Settings |
| Popup placement | Trigger & Popup / Settings |
| LSUIElement / activation policy | App Shell |

---

## Sources

- Apple Developer Documentation: `NSPanel`, `NSPasteboard`, activation policy APIs
- Apple Developer Documentation: Translation framework and language availability APIs
- Well-established macOS utility interaction patterns (menu bar apps, transient panels, clipboard-trigger workflows)

---
*Pitfalls research for: macOS menu bar selected-text translation utility (Transy)*
*Researched: 2026-03-14*

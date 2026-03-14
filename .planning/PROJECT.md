# Transy

## What This Is

Transy is a lightweight macOS menu bar translator for personal Japanese/English reading assistance. When the user selects text and presses `Command+C` twice, the app captures the selection, opens a native-feeling popup, shows the original text in a skeleton-loading style while translation is in flight, and then replaces it with the translated result in a preconfigured target language using Apple's Translation framework when the required on-device models are available. It is motivated by a desire for a faster, more macOS-native alternative to DeepL for quick reading flow.

## Core Value

Selected text turns into a natural translation almost instantly without breaking the user's reading flow.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] User can trigger translation of selected text by pressing `Command+C` twice.
- [ ] User can see a lightweight popup that first reflects the source text as a loading placeholder and then swaps to the translated text.
- [ ] User can run the app as a macOS menu bar utility without showing a Dock icon.
- [ ] User can change the target translation language and manage any required on-device translation model availability from a separate settings window.

### Out of Scope

- Translation history or clipboard-management features — v1 should stay focused on instant translation of the current selection.
- Manual text entry or compose flows — the primary interaction is translating text selected in other apps.
- Shortcut remapping and extensive UI customization — defer until the core translation loop proves valuable.
- Team/shared workflows — this is currently optimized for the creator's personal reading workflow.

## Context

The app is being built first for the creator's own day-to-day Japanese/English reading workflow on macOS. The reference experience is DeepL, but the main frustration is that DeepL feels too slow and its UI does not feel native enough on macOS. The desired UX is menu-bar-first, always available, visually lightweight, and optimized for fast "glance and continue reading" usage rather than a full translation workspace. After researching backend options, the initial translation strategy is to prefer Apple's Translation framework to maximize speed, privacy, and native integration, while keeping room for provider abstraction later if quality gaps emerge.

## Constraints

- **Platform**: macOS menu bar app — it must fit naturally into macOS behavior, stay resident in the menu bar, and remain hidden from the Dock.
- **Compatibility**: macOS 15+ — Apple's Translation framework is the selected backend and sets the minimum supported OS version.
- **Performance**: Near-immediate feedback for normal selected text — speed is the main reason this project exists.
- **UX**: Native-feeling transient popup — the UI should feel lighter and more macOS-like than DeepL.
- **Scope**: Focused v1 — only the selected-text translation loop and target-language settings are required initially.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Menu bar-only app with no Dock presence | Keeps the tool ambient and available without feeling like a full app window | — Pending |
| Double-press `Command+C` as the trigger | Reuses an existing selection-copy gesture with minimal friction | — Pending |
| Popup shows the source text as a loading-state placeholder before replacement | Preserves context during translation and makes latency feel intentional | — Pending |
| Use Apple's Translation framework as the initial translation engine | Prioritizes local speed, privacy, and native macOS integration over cloud-provider flexibility | — Pending |
| Target language is configured in a separate settings window | Keeps the translation popup minimal and focused on the result | — Pending |

---
*Last updated: 2026-03-14 after requirements definition*

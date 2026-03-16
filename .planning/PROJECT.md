# Transy

## What This Is

Transy is a lightweight macOS menu bar translator for personal Japanese/English reading assistance. Select text in any app, press `Command+C` twice, and a native popup instantly shows the translation using Apple's on-device Translation framework. No network required, no focus stealing, clipboard is restored after capture.

## Core Value

Selected text turns into a natural translation almost instantly without breaking the user's reading flow.

## Current Milestone: v0.2.0 Popup UX Polish

**Goal:** Improve the translation popup so it handles long text gracefully and appears near the user's cursor instead of a fixed screen position.

**Target features:**
- Multi-line scrollable popup that wraps long text instead of truncating with ellipsis
- Cursor-proximate popup positioning near the text selection area

## Requirements

### Validated

- ✓ Menu bar utility with no Dock icon — v0.1.0
- ✓ Double ⌘C triggers translation of selected text — v0.1.0
- ✓ Lightweight popup with loading placeholder then translated result — v0.1.0
- ✓ Target language settings with model download guidance — v0.1.0

### Active

- [ ] Popup displays translated text with word wrapping and scrolling for long content
- [ ] Popup appears near the cursor / text selection position instead of a fixed screen location

### Out of Scope

- Translation history or clipboard-management features — v1 should stay focused on instant translation of the current selection.
- Manual text entry or compose flows — the primary interaction is translating text selected in other apps.
- Shortcut remapping and extensive UI customization — defer until the core translation loop proves valuable.
- Team/shared workflows — this is currently optimized for the creator's personal reading workflow.

## Context

Shipped v0.1.0 with 1,179 LOC Swift (app) + 710 LOC Swift (tests).
Tech stack: SwiftUI, AppKit, Apple Translation.framework, XcodeGen.
37 automated tests across 11 suites. 4 phases, 9 plans executed.
Built in 3 days (2026-03-14 → 2026-03-16).

## Constraints

- **Platform**: macOS menu bar app — it must fit naturally into macOS behavior, stay resident in the menu bar, and remain hidden from the Dock.
- **Compatibility**: macOS 15+ — Apple's Translation framework is the selected backend and sets the minimum supported OS version.
- **Performance**: Near-immediate feedback for normal selected text — speed is the main reason this project exists.
- **UX**: Native-feeling transient popup — the UI should feel lighter and more macOS-like than DeepL.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Menu bar-only app with no Dock presence | Keeps the tool ambient and available without feeling like a full app window | ✓ Good |
| Double-press `Command+C` as the trigger | Reuses an existing selection-copy gesture with minimal friction | ✓ Good |
| Popup shows the source text as a loading-state placeholder before replacement | Preserves context during translation and makes latency feel intentional | ✓ Good |
| Use Apple's Translation framework as the initial translation engine | Prioritizes local speed, privacy, and native macOS integration over cloud-provider flexibility | ✓ Good |
| Target language is configured in a separate settings window | Keeps the translation popup minimal and focused on the result | ✓ Good |
| Three-tier language reconciliation (exact → languageCode → fallback) | Handles region-qualified OS locales like "en-JP" matching supported "en" | ✓ Good |
| System Settings deep link with `.extension` suffix | Only reliable way to open Language & Region on macOS 13+ | ✓ Good |

---
*Last updated: 2026-03-16 after v0.2.0 milestone start*

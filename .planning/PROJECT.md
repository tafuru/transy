# Transy

## What This Is

Transy is a lightweight macOS menu bar translator for personal Japanese/English reading assistance. Select text in any app, press `Command+C` twice, and a native popup instantly shows the translation using Apple's on-device Translation framework. No network required, no focus stealing, clipboard is restored after capture.

## Core Value

Selected text turns into a natural translation almost instantly without breaking the user's reading flow.

## Current Milestone: v0.4.0 DevOps & Improvements

**Goal:** Establish CI/CD pipeline, automate releases with DMG packaging, add permission-free clipboard monitoring trigger, and simplify translation model downloads using framework-native UI.

**Target features:**
- GitHub Actions CI (SwiftLint + SwiftFormat + build + test)
- Automated release workflow (tag → DMG → GitHub Release)
- Clipboard monitoring trigger mode (no Accessibility permission required)
- Translation model download via framework-native UI

## Requirements

### Validated

- ✓ Menu bar utility with no Dock icon — v0.1.0
- ✓ Double ⌘C triggers translation of selected text — v0.1.0
- ✓ Lightweight popup with loading placeholder then translated result — v0.1.0
- ✓ Target language settings with model download guidance — v0.1.0
- ✓ Popup displays translated text with word wrapping and scrolling — v0.2.0
- ✓ Popup appears near cursor with edge-clamping — v0.2.0
- ✓ First-launch onboarding with Accessibility permission guidance — v0.3.0
- ✓ macOS-standard tabbed Settings UI (General / About) — v0.3.0
- ✓ Launch at Login toggle — v0.3.0
- ✓ CI pipeline with SwiftLint, SwiftFormat, build and test — Phase 10
- ✓ Automated release workflow with DMG packaging — Phase 11
- ✓ Permission-free clipboard monitoring trigger (replaces Double ⌘C) — Phase 12

### Active

(Requirements defined in REQUIREMENTS.md for v0.4.0)

### Out of Scope

- Popup auto-dismiss timer — deprioritized; clipboard monitoring mode makes auto-dismiss less relevant.
- Translation history or clipboard-management features — v1 should stay focused on instant translation of the current selection.
- Manual text entry or compose flows — the primary interaction is translating text selected in other apps.
- Shortcut remapping and extensive UI customization — defer until the core translation loop proves valuable.
- Team/shared workflows — this is currently optimized for the creator's personal reading workflow.

## Context

Shipped v0.3.0 with 2,258 LOC Swift (app + tests).
Tech stack: SwiftUI, AppKit, Apple Translation.framework, ServiceManagement.framework, XcodeGen.
50 automated tests across 13 suites. 9 phases, 16 plans executed across 3 milestones.
Built in 12 days (2026-03-14 → 2026-03-25).

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
| Pure Foundation PopupPositionCalculator | No AppKit dependency — fully unit testable with CGPoint/CGSize/CGRect | ✓ Good |
| NSWindow.didResizeNotification for content changes | Lightweight observation without KVO or Combine; triggers reposition on dynamic sizing | ✓ Good |
| Cursor captured once at trigger time | Popup stays anchored to original cursor position through content changes | ✓ Good |
| macOS-standard TabView for Settings | Follows platform conventions, scales to more tabs naturally | ✓ Good |
| SMAppService.mainApp for Login Items | System state as source of truth, no UserDefaults needed | ✓ Good |
| Proactive AX guidance on launch | Users never wonder why the app isn't working — guidance appears immediately | ✓ Good |
| Custom Binding for SMAppService toggle | Prevents onChange re-entry and initial side effects during .task | ✓ Good |

---

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-04-04 after Phase 12 completion*

# Transy

## What This Is

Transy is a lightweight macOS menu bar translator for personal Japanese/English reading assistance. Copy text in any app and a native popup instantly shows the translation using Apple's on-device Translation framework. No network required, no focus stealing, no Accessibility permission required.

## Core Value

Selected text turns into a natural translation almost instantly without breaking the user's reading flow.

## Current State: v0.5.0 IN PROGRESS — Phase 15 complete (chunked translation)

**Shipped:** 2026-04-04 — 13 phases, 22 plans, 4 milestones

**What works:**
- Copy text in any app → translation popup appears within ~500ms (clipboard monitoring, no permission required)
- On-device translation via Apple Translation framework (no network, private)
- Framework prompts for model downloads automatically when needed
- macOS-standard tabbed Settings (target language, launch at login)
- First-launch Accessibility onboarding removed (no longer needed)
- Full CI pipeline (SwiftLint + SwiftFormat + build + test on every PR)
- Automated releases (tag → DMG → GitHub Release)

**Tech stack:** SwiftUI, AppKit, Apple Translation.framework, ServiceManagement.framework, XcodeGen
**Code:** ~1,700 LOC Swift (app + tests), 50+ automated tests

## Current Milestone: v0.5.0 Translation Quality

**Goal:** Make all language pairs work and improve perceived speed and visual feedback during translation

**Target features:**
- English pivot translation — relay unsupported pairs (e.g. JP→DE) through English when Apple Translation has no direct model
- Shimmer animation — visualize translation loading state with a skeleton shimmer overlay
- Chunked translation — batch-translate up to 200-char sentence chunks via `translations(from:)`, speeding up long texts

## Constraints

- **Platform**: macOS menu bar app — it must fit naturally into macOS behavior, stay resident in the menu bar, and remain hidden from the Dock.
- **Compatibility**: macOS 15+ — Apple's Translation framework is the selected backend and sets the minimum supported OS version.
- **Performance**: Near-immediate feedback for normal selected text — speed is the main reason this project exists.
- **UX**: Native-feeling transient popup — the UI should feel lighter and more macOS-like than DeepL.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Menu bar-only app with no Dock presence | Keeps the tool ambient and available without feeling like a full app window | ✓ Good |
| ~~Double-press Command+C as the trigger~~ → Clipboard monitoring | Originally used Double ⌘C; replaced in v0.4.0 with clipboard monitoring — no Accessibility permission, simpler UX | ✓ Better |
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
| Proactive AX guidance on launch → removed in v0.4.0 | No longer needed: clipboard monitoring requires no Accessibility permission | ✓ Simplified |
| Custom Binding for SMAppService toggle | Prevents onChange re-entry and initial side effects during .task | ✓ Good |
| NSPasteboard.general.changeCount polling at 500ms | Lightweight, no entitlements, works in all apps | ✓ Good |
| Framework-native translation model download | Removed manual System Settings guidance — framework handles download prompts natively | ✓ Simpler |
| Removed preflight LanguageAvailability.status() call | Was causing double ML inference per translation; TranslationErrorMapper covers all error cases | ✓ Faster |

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
*Last updated: 2026-04-12 after Phase 15 chunked translation completion*

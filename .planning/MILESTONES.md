# Milestones

## v0.5.0 Translation Quality (Shipped: 2026-04-17)

**Phases completed:** 3 phases, 5 plans, 7 tasks
**Timeline:** 14 days (2026-04-04 → 2026-04-18)
**Codebase:** ~2,000 LOC Swift (app + tests), 60+ automated tests

**Key accomplishments:**

- Shimmer animation with gradient sweep overlay during translation loading — zero layout impact, Reduce Motion compliant
- NLTokenizer sentence-boundary chunking with greedy grouping and batch `translations(from:)` for long texts
- Automatic English pivot translation (source→EN→target) for unsupported language pairs with seamless shimmer continuity
- Swift 6 strict concurrency pattern: `nonisolated static func` + `@Sendable` closure for `.translationTask()` isolation boundaries
- 60+ automated tests including TextChunker (9), ShimmerModifier (3), TranslationErrorMapper (8), pivot config (2)

**Archives:** [milestones/v0.5.0-ROADMAP.md](milestones/v0.5.0-ROADMAP.md) · [milestones/v0.5.0-REQUIREMENTS.md](milestones/v0.5.0-REQUIREMENTS.md)

---

## v0.4.0 DevOps & Improvements (Shipped: 2026-04-04)

**Phases completed:** 4 phases, 6 plans
**Timeline:** 10 days (2026-03-25 → 2026-04-04)
**Codebase:** ~1,700 LOC Swift (app + tests)

**Key accomplishments:**

- CI pipeline with SwiftLint, SwiftFormat, build and test on every PR (macos-15)
- Release automation: git tag push → Release build → DMG → GitHub Release with auto-generated notes
- Permission-free clipboard monitoring (NSPasteboard changeCount polling) replaces Double ⌘C — no Accessibility permission needed
- Framework-native translation model download UI removes manual System Settings guidance
- Preflight language detection removed — eliminated redundant ML inference per translation

**Archives:** [milestones/v0.4.0-ROADMAP.md](milestones/v0.4.0-ROADMAP.md) · [milestones/v0.4.0-REQUIREMENTS.md](milestones/v0.4.0-REQUIREMENTS.md)

---

## v0.3.0 Onboarding & Settings (Shipped: 2026-03-25)

**Phases completed:** 3 phases, 3 plans
**Timeline:** 5 days (2026-03-21 → 2026-03-25)
**Codebase:** 2,258 LOC Swift (app + tests)

**Key accomplishments:**

- macOS-standard tabbed Settings window (General/About) with Form+Section grouped layout
- Git tag-based version automation via post-build script
- Proactive Accessibility permission guidance on first launch with why-explanation
- Launch at Login toggle backed by SMAppService.mainApp (system state as source of truth)
- 5/5 requirements satisfied, 10/10 cross-phase integrations verified

**Archives:** [milestones/v0.3.0-ROADMAP.md](milestones/v0.3.0-ROADMAP.md) · [milestones/v0.3.0-REQUIREMENTS.md](milestones/v0.3.0-REQUIREMENTS.md)

---

## v0.2.0 Popup UX Polish (Shipped: 2026-03-21)

**Phases completed:** 2 phases, 4 plans
**Timeline:** 5 days (2026-03-16 → 2026-03-21)
**Codebase:** 2,183 LOC Swift (app + tests)

**Key accomplishments:**

- Word wrapping and vertical scrolling for long translations via ScrollView + dynamic height sizing
- Pure PopupPositionCalculator with cursor-proximate placement, flip-above on bottom overflow, and edge-clamping
- NSWindow.didResizeNotification-driven reposition on content size changes
- 13 new tests (4 layout + 9 positioning), 50 total across 13 suites
- PR review hardening: safe MainActor isolation, panel-wider-than-screen guard, cursor-outside-visibleFrame handling

**Archives:** [milestones/v0.2.0-ROADMAP.md](milestones/v0.2.0-ROADMAP.md) · [milestones/v0.2.0-REQUIREMENTS.md](milestones/v0.2.0-REQUIREMENTS.md)

---

## v0.1.0 MVP (Shipped: 2026-03-16)

**Phases completed:** 4 phases, 9 plans
**Timeline:** 3 days (2026-03-14 → 2026-03-16)
**Codebase:** 1,179 LOC app + 710 LOC tests (Swift)

**Key accomplishments:**

- Menu bar app shell with LSUIElement, xcodegen build system, and Settings scene
- Double ⌘C hotkey detection, Accessibility permission guidance, clipboard-safe text capture, floating popup
- On-device translation via Apple Translation framework with auto source language detection
- Target language picker with persistence, three-tier locale reconciliation, and model download guidance
- 37 automated tests across 11 suites, 8/8 UAT passed, 12/12 requirements satisfied

**Archives:** [milestones/v0.1.0-ROADMAP.md](milestones/v0.1.0-ROADMAP.md) · [milestones/v0.1.0-REQUIREMENTS.md](milestones/v0.1.0-REQUIREMENTS.md)

---

# Retrospective: Transy

## Milestone: v0.3.0 — Onboarding & Settings

**Shipped:** 2026-03-25
**Phases:** 3 | **Plans:** 3

### What Was Built
- macOS-standard tabbed Settings window (General/About) with Form+Section grouped layout
- Git tag-based version automation via post-build script
- Proactive Accessibility permission guidance on first launch with why-explanation
- Launch at Login toggle backed by SMAppService.mainApp

### What Worked
- Small, focused phases (1 plan each) kept execution fast and reviews manageable
- PR review by Copilot caught real bugs (onChange re-entry, initial side effects)
- Custom Binding pattern was a clean fix for the SMAppService toggle lifecycle issue
- Deferring SET-04 (auto-dismiss) kept scope tight and delivered faster

### What Was Inefficient
- STATE.md frontmatter keeps reverting to v0.1 via gsd-tools — fixed manually 3 times across milestones
- VERIFICATION.md date bug (2025 vs 2026) required manual fix in Phase 7 and 8
- Phase 7 SUMMARY.md missing `requirements-completed` frontmatter — discovered during audit

### Patterns Established
- SMAppService.mainApp pattern: read `.status` on `.task`, register/unregister via custom `Binding(get:set:)`, re-read after call
- Proactive permission guidance: check on launch, not on user-triggered action
- Safe URL construction: guard-let for system deep links

### Key Lessons
- Custom `Binding(get:set:)` is the correct pattern for toggles backed by system state that can fail — avoids `.onChange` re-entry
- PR reviews reliably catch lifecycle bugs that automated verification misses
- Deferring non-essential features (SET-04) is better than shipping partial implementations

### Cost Observations
- Sessions: 3 (Phase 7+8 in one, Phase 9 in one, audit+completion in one)
- All phases under 2 minutes execution time each
- Notable: v0.3.0 was the fastest milestone per-phase despite more complex features

---

## Milestone: v0.2.0 — Popup UX Polish

**Shipped:** 2026-03-21
**Phases:** 2 | **Plans:** 4

### What Was Built
- Word wrapping and vertical scrolling for long translations
- Pure Foundation PopupPositionCalculator with cursor-proximate placement and edge-clamping
- Dynamic reposition on content size changes via NSWindow.didResizeNotification

### What Worked
- Foundation-only calculator enabled comprehensive unit testing (9 positioning tests)
- PR review hardening caught edge cases (panel-wider-than-screen, cursor-outside-visibleFrame)

### What Was Inefficient
- Phase 6 needed 2 plans (initial + PR review fixes) — could have been caught in first pass

### Key Lessons
- Pure Foundation types for geometry calculations = full testability without AppKit mocks
- Capture cursor location once at trigger time — don't track it dynamically

---

## Milestone: v0.1.0 — MVP

**Shipped:** 2026-03-16
**Phases:** 4 | **Plans:** 9

### What Was Built
- Menu bar app shell with LSUIElement and xcodegen
- Double ⌘C hotkey detection with Accessibility permission guidance
- On-device translation via Apple Translation framework
- Target language settings with three-tier locale reconciliation

### What Worked
- GSD workflow delivered a working MVP in 3 days
- 37 automated tests across 11 suites provided confidence for rapid iteration
- xcodegen as single source of truth eliminated Xcode project merge conflicts

### What Was Inefficient
- 9 plans across 4 phases was too granular for MVP — could consolidate
- Translation framework cancellation latency remains unresolved

### Key Lessons
- NSPanel with `.nonactivatingPanel` is the correct pattern for floating popups — SwiftUI WindowGroup steals focus
- Three-tier language reconciliation handles real-world locale diversity (en-JP → en)

---

## Cross-Milestone Trends

| Metric | v0.1.0 | v0.2.0 | v0.3.0 |
|--------|--------|--------|--------|
| Phases | 4 | 2 | 3 |
| Plans | 9 | 4 | 3 |
| Timeline | 3 days | 5 days | 5 days |
| LOC (cumulative) | 1,889 | 2,183 | 2,258 |
| Tests | 37 | 50 | 50 |
| Requirements | 12 | 2 | 5 |

**Velocity trend:** Plans per phase decreasing (2.25 → 2.0 → 1.0) — phases becoming more focused and well-scoped.

**Quality trend:** PR reviews consistently catch 4-6 issues per milestone — valuable gate before merge.

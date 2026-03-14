# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-14)

**Core value:** Selected text turns into a natural translation almost instantly without breaking the user's reading flow.
**Current focus:** Phase 1 — App Shell

## Current Position

Phase: 1 of 4 (App Shell)
Plan: 0 of 2 in current phase
Status: Ready to plan
Last activity: 2026-03-14 — Roadmap created, 4 phases defined, 12/12 v1 requirements mapped

Progress: [░░░░░░░░░░] 0%

## Performance Metrics

**Velocity:**
- Total plans completed: 0
- Average duration: —
- Total execution time: —

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| - | - | - | - |

**Recent Trend:**
- Last 5 plans: —
- Trend: —

*Updated after each plan completion*

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- [Pre-phase]: Apple Translation framework chosen as backend (not DeepL) — on-device speed, privacy, macOS-native integration
- [Pre-phase]: Apple Translation is sandbox-compatible, but the chosen global-monitoring approach and its capability model must be validated in Phase 1 before locking the final sandbox configuration
- [Pre-phase]: LSUIElement set via Info.plist, not entitlements (common mistake to avoid)
- [Pre-phase]: Popup must be NSPanel with `.nonactivatingPanel` styleMask from day one — SwiftUI WindowGroup is a hard anti-pattern here

### Pending Todos

None yet.

### Blockers/Concerns

- Phase 2: Accessibility is required, and any additional privacy permissions depend on the final monitoring API; onboarding must validate and explain the chosen path explicitly
- Phase 2: Clipboard read must be delayed ~80ms after trigger fires (source app hasn't written yet at monitor fire time)
- Phase 3: Apple Translation framework requires macOS 15+ — sets hard deployment target floor

## Session Continuity

Last session: 2026-03-14
Stopped at: Roadmap created — ready to plan Phase 1
Resume file: None

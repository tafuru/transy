---
phase: 03-translation-loop
plan: 02
subsystem: ui
tags: [swift, swiftui, translation, apple-translation, popup, lifecycle, cancellation]

# Dependency graph
requires:
  - phase: 03-translation-loop/03-01
    provides: TranslationCoordinator, TranslationAvailabilityClient, TranslationErrorMapper, and request-scoped stale-write guards
provides:
  - View-scoped Apple Translation execution inside PopupView with inline loading, result, and error rendering
  - AppDelegate wiring that begins normalized translation requests before showing the popup and dismisses active requests on close
  - Popup lifecycle hardening for rapid re-trigger and dismiss teardown so stale results never visibly overwrite newer content
  - Recorded follow-up todos for translation-model install guidance and Translation framework cancellation latency
affects: [04-settings, translation-runtime-validation]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Keep the Translation framework session view-scoped in SwiftUI via translationTask rather than storing it in an app service"
    - "Reuse one NSPanel, but replace hosted SwiftUI content on re-trigger and dismiss so view-scoped translation work tears down promptly"
    - "Treat Translation framework cancellation latency as a known limitation once visible correctness is fixed and app-side teardown paths are exhausted"

key-files:
  created: []
  modified:
    - Transy/AppDelegate.swift
    - Transy/Popup/PopupController.swift
    - Transy/Popup/PopupView.swift
    - TransyTests/TranslationTaskConfigurationReloaderTests.swift
    - .planning/todos/pending/2026-03-15-add-translation-model-install-guidance.md
    - .planning/todos/pending/2026-03-15-track-translation-cancellation-latency.md

key-decisions:
  - "Popup reuse stays at the NSPanel level, but the hosted SwiftUI subtree must be torn down on re-trigger and dismiss so translationTask restarts and cancels as quickly as AppKit allows"
  - "Phase 3 ships the macOS 15-compatible translationTask path only; a Tahoe-only TranslationSession.cancel() experiment was removed after it showed no meaningful user-visible improvement"
  - "Translation-framework cancellation latency remains a documented known limitation, not a hidden defect, while visible correctness requirements are considered satisfied"

patterns-established:
  - "PopupView loading state owns translationTask and writes results/errors only when request identity still matches the active coordinator request"
  - "Dismiss correctness requires both coordinator.dismiss() and panel.contentView teardown"
  - "Live smoke-test findings that cannot be cleanly solved in-scope become explicit planning todos before plan closure"

requirements-completed: [TRAN-01, TRAN-02, TRAN-03]

# Metrics
duration: 1h 48m
completed: "2026-03-15"
---

# Phase 3 Plan 02: Popup Translation Wiring Summary

**PopupView now runs Apple Translation in-place so the muted source-text popup resolves to inline English results or short inline errors, with lifecycle guards that prevent stale re-trigger and dismiss behavior from resurfacing older content.**

## Performance

- **Duration:** 1h 48m
- **Started:** 2026-03-15T01:48:09Z
- **Completed:** 2026-03-15T03:36:11Z
- **Tasks:** 3
- **Files modified:** 10

## Accomplishments

- Upgraded `PopupView` from a static muted placeholder into a state-driven surface that performs preflight, runs `translationTask`, and swaps between loading, translated result, and short inline error states in the same compact popup.
- Wired `AppDelegate` into the Phase 3 translation coordinator so normalized source text begins a request before popup presentation and dismiss clears active request state before clipboard restore.
- Hardened the popup lifecycle after live smoke feedback so rapid re-trigger and dismiss no longer allow stale overwrites or late popup reappearance, then recorded the remaining Translation-framework cancellation latency as an explicit follow-up limitation.

## Task Commits

Each task was committed atomically, with checkpoint follow-up commits kept separate:

1. **Task 1: Upgrade PopupView and PopupController to state-driven translation rendering** — `ee6483f` (feat)
2. **Task 2: Wire AppDelegate trigger, re-trigger, and dismiss paths into the translation coordinator** — `89afe88` (feat)
3. **Checkpoint follow-up: capture missing-model install guidance for a later phase** — `3096120` (docs)
4. **Checkpoint follow-up: restart popup translation on rapid retrigger** — `a933162` (fix)
5. **Checkpoint follow-up: fully restart popup translation lifecycle on retrigger** — `dd141cc` (fix)
6. **Checkpoint follow-up: tear down popup translation work on dismiss** — `2567731` (fix)
7. **Checkpoint follow-up: trial Tahoe-only cancellation path** — `eb2b7c4` (fix)
8. **Checkpoint follow-up: remove ineffective Tahoe-only cancellation path** — `6eeb3ff` (refactor)
9. **Checkpoint follow-up: record known limitation for Translation-framework cancellation latency** — `9281659` (docs)
10. **Task 3: Live smoke-test acceptance** — accepted by user with the recorded known limitation; no code commit

## Files Created/Modified

- `Transy/Popup/PopupView.swift` — renders loading/result/error popup states, runs `translationTask`, guards writes by active request identity, and keeps failure copy app-owned.
- `Transy/Popup/PopupController.swift` — keeps one non-activating panel but now tears down hosted SwiftUI content on re-trigger and dismiss so translation work cancels with the hosted view lifecycle.
- `Transy/AppDelegate.swift` — begins normalized translation requests before popup show and dismisses active requests before restoring clipboard contents.
- `TransyTests/TranslationTaskConfigurationReloaderTests.swift` — locks the request-configuration reload and popup-dismiss teardown behavior found during live verification.
- `Transy/Translation/TranslationAvailabilityClient.swift` — small target-language access change supporting the popup translation wiring.
- `TransyTests/TranslationAvailabilityClientTests.swift` — covers the preflight cancellation behavior needed for silent popup teardown.
- `Transy.xcodeproj/project.pbxproj` — regenerated to include the new translation-task lifecycle test coverage.
- `.planning/todos/pending/2026-03-15-add-translation-model-install-guidance.md` — captures the missing user guidance path for Apple model installation.
- `.planning/todos/pending/2026-03-15-track-translation-cancellation-latency.md` — captures the accepted known limitation around Translation-framework cancellation latency after app-side lifecycle fixes.

## Decisions Made

1. **Keep translation execution inside `PopupView`** — Apple Translation remains view-scoped through `translationTask`; the app does not store or manage a long-lived session object outside the popup lifecycle.
2. **Tear down hosting content, not just popup visibility** — re-trigger and dismiss both remove the hosted SwiftUI subtree so the next request gets a fresh loading view and the old translation task loses its hosting context immediately.
3. **Do not keep the Tahoe-only cancellation experiment** — `TranslationSession.cancel()` behind `if #available(macOS 26.0, *)` did not materially improve the user-observed latency, so the accepted branch returns to the simpler macOS 15-compatible path.
4. **Close the plan with a documented limitation instead of a misleading “fully fixed” claim** — visible correctness is accepted for Phase 3, but the remaining latency investigation stays tracked for future runtime/framework validation.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Rapid re-trigger did not reliably restart the view-scoped translation session**
- **Found during:** Task 3 live smoke-test continuation
- **Issue:** Re-triggering with new source text could leave the new request feeling queued behind the previous one because the existing translation configuration was not being invalidated/reloaded aggressively enough.
- **Fix:** Reloaded the `TranslationSession.Configuration` on request changes and added focused test coverage for retrigger configuration invalidation.
- **Files modified:** `Transy/Popup/PopupView.swift`, `TransyTests/TranslationTaskConfigurationReloaderTests.swift`
- **Verification:** `xcodebuild test -scheme Transy -destination 'platform=macOS'`
- **Committed in:** `a933162`

**2. [Rule 1 - Bug] Reusing the NSPanel alone kept too much of the old SwiftUI translation lifecycle alive**
- **Found during:** Task 3 live smoke-test continuation
- **Issue:** Even after re-trigger, the reused panel could keep the previous hosted subtree alive long enough for request B to feel blocked by request A.
- **Fix:** Cleared `panel.contentView` before installing the next popup content and forced a fresh loading-view identity per request.
- **Files modified:** `Transy/Popup/PopupController.swift`, `Transy/Popup/PopupView.swift`
- **Verification:** `xcodebuild test -scheme Transy -destination 'platform=macOS'`
- **Committed in:** `dd141cc`

**3. [Rule 1 - Bug] Dismiss only hid the panel, leaving translationTask work alive after the popup closed**
- **Found during:** Task 3 live smoke-test continuation
- **Issue:** Outside-click or Escape dismiss removed the surface but did not tear down the hosted SwiftUI tree, allowing in-flight work to outlive the visible popup.
- **Fix:** Removed hosted popup content in `dismiss()` and added popup-controller coverage for dismiss teardown.
- **Files modified:** `Transy/Popup/PopupController.swift`, `TransyTests/TranslationTaskConfigurationReloaderTests.swift`, `Transy.xcodeproj/project.pbxproj`
- **Verification:** `xcodebuild test -scheme Transy -destination 'platform=macOS'`
- **Committed in:** `2567731`

---

**Total deviations:** 3 auto-fixed (3 Rule 1 bugs)
**Impact on plan:** All follow-up fixes were directly required to satisfy the popup lifecycle and stale-result correctness expectations exposed by live verification. No scope creep beyond documented planning todos.

## Checkpoint Continuation Follow-up

- Missing-model verification exposed a product gap rather than a Phase 3 correctness bug, so the install path was recorded for Phase 4 in `.planning/todos/pending/2026-03-15-add-translation-model-install-guidance.md` (`3096120`).
- After the visible stale-overwrite and late-reappearance bugs were fixed, a remaining latency issue still made a short request B feel delayed after a longer request A.
- A Tahoe-only experiment wrapped popup translation work in a cancellation handler and called `TranslationSession.cancel()` on macOS 26+ (`eb2b7c4`), but user testing showed no meaningful improvement.
- The Tahoe-only path was therefore removed to preserve the simpler accepted implementation (`6eeb3ff`), and the remaining framework/runtime behavior was captured as a known limitation todo (`9281659`).

## Known Limitation Accepted for Phase 3

- The app now satisfies the accepted visible-correctness bar: no stale overwrite, no late popup reappearance after dismiss, inline errors stay in the popup, and lifecycle behavior is correct.
- A separate latency issue remains: when a long translation request is followed by a short request, the new request can still feel delayed even after popup teardown and rebuild.
- Current evidence points to Translation-framework/runtime cancellation behavior rather than an unfixed app-side stale-state bug.
- This limitation is explicitly tracked in `.planning/todos/pending/2026-03-15-track-translation-cancellation-latency.md` and was accepted by the user for Phase 3 closure.

## Issues Encountered

- Live framework behavior mattered more than unit coverage for cancellation timing; automated tests could prove stale-write suppression and lifecycle teardown, but not eliminate real runtime latency.
- The missing-model path was correct but incomplete from a UX standpoint because users currently receive a short inline error without an in-app explanation of where Apple installs translation models.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 3 is complete from the product-flow perspective: Transy can now show loading, result, and inline error states in the same popup with accepted stale-result protections.
- Phase 4 should own target-language settings and model-install guidance, using the recorded todo rather than revisiting Phase 3 popup scope.
- Future investigation can revisit Translation-framework cancellation latency on newer macOS/Xcode/runtime combinations without reintroducing the reverted Tahoe-only path by default.

## Self-Check: PASSED

- Verified `.planning/phases/03-translation-loop/03-02-SUMMARY.md` exists on disk.
- Verified referenced commits `ee6483f`, `89afe88`, `3096120`, `a933162`, `dd141cc`, `2567731`, `eb2b7c4`, `6eeb3ff`, and `9281659` exist in git history.

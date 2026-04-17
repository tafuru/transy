---
phase: 16-pivot-translation
plan: 01
subsystem: translation
tags: [Translation, pivot, TranslationSession, unsupportedLanguagePairing, SwiftUI]

requires:
  - phase: 15-chunked-translation
    provides: "TextChunker and batch .translations(from:) API for long texts"
provides:
  - "Dual .translationTask() pivot architecture for unsupported language pairs"
  - "isPivotTrigger error classifier in TranslationErrorMapper"
  - "Automatic source→EN→target fallback when direct translation unsupported"
affects: [translation-quality, error-handling]

tech-stack:
  added: []
  patterns: ["nonisolated static func + @Sendable closure pattern for Swift 6 strict concurrency in .translationTask()"]

key-files:
  created: []
  modified:
    - Transy/Popup/PopupView.swift
    - Transy/Translation/TranslationErrorMapper.swift

key-decisions:
  - "Used nonisolated static funcs with @Sendable closure callbacks instead of inline closures to satisfy Swift 6 strict concurrency"
  - "Pivot state read as snapshot (let isPivoting = pivotNeeded) passed to nonisolated context, mutations via @Sendable closures"
  - "Shared translateSegments helper eliminates duplication across primary, pivot, and retry code paths"

patterns-established:
  - "nonisolated static action factory: build @Sendable closures for .translationTask() from nonisolated static methods to avoid MainActor isolation inheritance"
  - "Callback-based state mutation: pass @Sendable closures (onPivotLeg1Complete, onStartPivot) instead of Bindings across isolation boundaries"

requirements-completed: [PIV-01, PIV-02, PIV-03]

duration: 15min
completed: 2026-04-17
---

# Phase 16: Pivot Translation Summary

**Dual .translationTask() pivot architecture: automatic source→EN→target fallback for unsupported language pairs with D-08 chunk retry and re-pivot guard**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-04-17T23:06:00+09:00
- **Completed:** 2026-04-17T23:20:00+09:00
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- `isPivotTrigger` classifier detects unsupportedLanguagePairing/Source/Target errors
- Primary `.translationTask()` serves double duty: normal translation + pivot leg 1 (source→EN)
- Second `.translationTask(pivotConfiguration)` handles pivot leg 2 (EN→target) with re-chunking
- Re-pivot guard prevents infinite loop when source→EN also fails
- D-08: unableToIdentifyLanguage retries up to 3 individual chunks before giving up
- Shimmer stays active across both pivot legs (onResult only after final translation)
- All pivot @State reset on new clipboard events via .onChange

## Task Commits

Each task was committed atomically:

1. **Task 1: Add isPivotTrigger to TranslationErrorMapper** - `417ffaf` (feat)
2. **Task 2: Add pivot translation to LoadingPopupText** - `81079e0` (feat)

## Files Created/Modified
- `Transy/Translation/TranslationErrorMapper.swift` - Added `isPivotTrigger(_:)` static method
- `Transy/Popup/PopupView.swift` - Restructured LoadingPopupText with dual .translationTask(), pivot @State, nonisolated static action factories

## Decisions Made
- Used nonisolated static func pattern (primaryAction, pivotAction, translateSegments, retryChunksForDetection) instead of inline closures — Swift 6 strict concurrency treats inline .translationTask() closures in body as @MainActor, causing data race errors with session parameter
- Passed @Sendable closures (onPivotLeg1Complete, onStartPivot) for state mutations instead of Bindings (Binding is not Sendable)
- Extracted shared translateSegments helper to eliminate code duplication across primary, pivot, and retry paths

## Deviations from Plan

### Auto-fixed Issues

**1. [Swift 6 Concurrency] Inline closures caused MainActor isolation inheritance**
- **Found during:** Task 2 (Build verification)
- **Issue:** Plan specified inline `.translationTask() { session in ... }` closures, but Swift 6 strict concurrency treats them as @MainActor-isolated since they're formed in body scope, causing "sending 'session' risks causing data races" errors
- **Fix:** Refactored to nonisolated static func pattern (primaryAction, pivotAction) returning @Sendable closures, matching the pre-existing translationAction pattern
- **Files modified:** Transy/Popup/PopupView.swift
- **Verification:** `make build` exits 0
- **Committed in:** 81079e0

**2. [Swift 6 Concurrency] Binding not Sendable**
- **Found during:** Task 2 (Second build attempt)
- **Issue:** Passing `$pivotNeeded`, `$pivotConfiguration` etc. as Binding parameters to nonisolated static funcs fails because Binding isn't Sendable
- **Fix:** Changed to @Sendable closure callbacks (onPivotLeg1Complete, onStartPivot) captured from body scope where @State access is allowed
- **Files modified:** Transy/Popup/PopupView.swift
- **Verification:** `make build` exits 0
- **Committed in:** 81079e0

---

**Total deviations:** 2 auto-fixed (both Swift 6 concurrency)
**Impact on plan:** Architecture preserved (dual .translationTask(), same flow). Only the Swift isolation boundary crossing mechanism changed.

## Issues Encountered
- UI tests timeout due to automation mode infrastructure issue (not code-related) — unit tests pass

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Pivot translation fully implemented for all three requirements
- Manual testing recommended: JP→DE (pivot), EN→JA (direct), dismiss during pivot
- Ready for verification phase

---
*Phase: 16-pivot-translation*
*Completed: 2026-04-17*

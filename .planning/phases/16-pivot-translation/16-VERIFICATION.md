---
phase: 16-pivot-translation
verified: 2026-04-18T03:00:00+09:00
status: passed
score: 5/5 must-have truths verified; all gaps closed
gaps_closed:
  - truth: "Test coverage for pivot error classification and configuration"
    resolution: "Created TranslationErrorMapperTests.swift (8 tests) and added 2 pivot config tests to TranslationTaskConfigurationReloaderTests.swift"
    commit: "458f0d5"
---

# Phase 16: Pivot Translation Verification Report

**Phase Goal:** When Apple Translation reports an unsupported language pair, the app silently chains two translations through English so the user still gets a result
**Verified:** 2026-04-18T03:00:00+09:00
**Status:** passed
**Re-verification:** Yes — gaps closed (commit 458f0d5)

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Unsupported language pair (e.g. JP→DE) triggers automatic source→EN→target pivot chain — no error shown | ✓ VERIFIED | `isPivotTrigger` catches errors at L219, `onStartPivot` reconfigures to EN target (L151-163), `pivotAction` translates EN→target (L240-273) |
| 2 | Shimmer animation plays continuously across both pivot legs without flicker or partial state | ✓ VERIFIED | `.shimmer()` on loading view (L125), `onResult` only called after leg 2 (L258), `onPivotLeg1Complete` stores intermediate text without calling `onResult` (L197-198) |
| 3 | When pivot also fails (EN→target unsupported), user sees "This language pair isn't supported." error | ✓ VERIFIED | Re-pivot guard at L221 and pivotAction catch at L266 both invoke `onError` with `TranslationErrorMapper.unsupportedLanguagePair` = "This language pair isn't supported." (TranslationErrorMapper.swift L5) |
| 4 | Intermediate English text is never shown to the user (onResult called only after leg 2) | ✓ VERIFIED | `primaryAction` routes to `onPivotLeg1Complete` when isPivoting (L197-198), stores text in `@State pivotIntermediateText` (L143); `onResult` only appears in `pivotAction` (L258) after leg 2 |
| 5 | New clipboard event during mid-pivot cleanly cancels stale pivot via .id(requestID) teardown | ✓ VERIFIED | `.id(requestID)` on LoadingPopupText (PopupView L18) destroys/recreates view; `onChange(of: requestContext.requestID)` resets `pivotNeeded`, `pivotIntermediateText`, `pivotConfiguration` (L127-131) |

**Score:** 5/5 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `Transy/Translation/TranslationErrorMapper.swift` | Error classification for pivot detection | ✓ VERIFIED | `isPivotTrigger(_:)` at L9 checks `unsupportedLanguagePairing`, `unsupportedSourceLanguage`, `unsupportedTargetLanguage`. Note: PLAN specified name `isUnsupportedPairError`; implementation used `isPivotTrigger` — functionally equivalent |
| `Transy/Popup/PopupView.swift` | Dual .translationTask(), pivot state, pivotAction | ✓ VERIFIED | Two `.translationTask()` modifiers (L135, L168), `@State pivotConfiguration` (L111), `pivotAction` (L240). Note: PLAN specified `PivotTranslationState` type; implementation uses individual @State vars — functionally equivalent, simpler |
| `TransyTests/TranslationErrorMapperTests.swift` | Unit tests for error classification | ✓ VERIFIED | 8 tests covering isPivotTrigger (3 positive, 2 negative) and message(for:) (3 mapping tests) |
| `TransyTests/TranslationTaskConfigurationReloaderTests.swift` | Unit tests for pivot configuration factory | ✓ VERIFIED | 2 pivot config tests added (D-02 explicit EN source + non-nil check) |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| translationAction catch block | TranslationErrorMapper.isPivotTrigger | Error classification before generic handler | ✓ WIRED | L219: `catch where TranslationErrorMapper.isPivotTrigger(error)` — ordered before generic catch at L230. Note: PLAN pattern `isUnsupportedPairError` was renamed to `isPivotTrigger` |
| LoadingPopupText.body | .translationTask(pivotConfiguration) | Second translation task modifier for EN→target | ✓ WIRED | L168-169: `.translationTask(pivotConfiguration, action: Self.pivotAction(...))` — multiline formatting caused initial grep miss but confirmed by direct inspection |
| Pivot trigger detection | Locale.Language(identifier: "en") | Source→EN reconfiguration | ✓ WIRED | L146 (pivotConfiguration source=en), L157 (config.target=en fallback), L159 (config.target=en) — English explicitly set as pivot relay |
| pivotAction success | onResult | Final result delivery after leg 2 only (D-04) | ✓ WIRED | L258: `await onResult(...)` inside pivotAction after leg 2 translation. In primaryAction, when isPivoting, `onPivotLeg1Complete` is called instead (L198) — D-04 fully honored |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| PopupView.swift (LoadingPopupText) | pivotIntermediateText | primaryAction → onPivotLeg1Complete callback | Yes — `translateSegments` calls `session.translate()` / `session.translations(from:)` (real Apple Translation API) | ✓ FLOWING |
| PopupView.swift (pivotAction) | translatedText | `translateSegments(session:segments:fallbackText:)` | Yes — re-chunks intermediate text and translates via real TranslationSession | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Build succeeds | `make build` (exit code) | Exit code 0, no errors | ✓ PASS |
| isPivotTrigger function exists and is callable | grep confirmed at TranslationErrorMapper.swift L9 | `static func isPivotTrigger(_ error: any Error) -> Bool` | ✓ PASS |
| Dual .translationTask modifiers present | grep + line inspection | Two modifiers at L135 and L168 | ✓ PASS |
| Pivot state reset on new request | onChange handler at L126-131 | Resets pivotNeeded, pivotIntermediateText, pivotConfiguration | ✓ PASS |
| Commits exist | `git log --oneline` | `417ffaf` (isPivotTrigger) and `81079e0` (pivot translation) confirmed | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| PIV-01 | 16-01-PLAN | On `unsupportedLanguagePairing` error, automatically falls back to source→EN→target two-leg chain | ✓ SATISFIED | `isPivotTrigger` catches error (L219), `onStartPivot` reconfigures (L151-163), dual `.translationTask` completes chain |
| PIV-02 | 16-01-PLAN | Shimmer continues throughout entire pivot sequence (seamless to user) | ✓ SATISFIED | `.shimmer()` active on loading view (L125), `onResult` only after leg 2 (L258), view stays in loading state |
| PIV-03 | 16-01-PLAN | If pivot also fails (EN path unavailable), appropriate error message shown | ✓ SATISFIED | Re-pivot guard (L221) and pivotAction catch (L266) both show `unsupportedLanguagePair` message per D-10 |

**Orphaned requirements:** None — all 3 PIV requirements mapped in REQUIREMENTS.md to Phase 16 are covered by plan 16-01.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| — | — | No TODOs, FIXMEs, placeholders, empty returns, or debug logging found | — | — |

**Clean:** Both modified files (PopupView.swift, TranslationErrorMapper.swift) are free of anti-patterns.

### Human Verification Required

### 1. JP→DE Pivot Translation (PIV-01)

**Test:** Select Japanese text, set target language to German (or another pair unsupported by Apple Translation). Trigger translation.
**Expected:** Translation appears after a brief delay. No error message. No flicker between legs.
**Why human:** Requires running macOS app with Apple Translation framework; language pair support varies by installed models.

### 2. Shimmer Continuity During Pivot (PIV-02)

**Test:** Trigger a pivot translation and watch the popup.
**Expected:** Shimmer plays smoothly from start to finish — no intermediate blank/text state between legs.
**Why human:** Visual animation timing and smoothness cannot be verified programmatically.

### 3. Pivot Failure Error Display (PIV-03)

**Test:** Trigger a language pair where EN→target is also unsupported (may be difficult to find naturally).
**Expected:** "This language pair isn't supported." message displayed. No crash or blank popup.
**Why human:** Requires specific language pair that fails both direct and pivot paths.

### 4. Mid-Pivot Clipboard Event

**Test:** Start a pivot translation, then immediately copy new text to clipboard before it finishes.
**Expected:** Old translation cleanly cancels, new translation starts fresh with no stale pivot state.
**Why human:** Timing-dependent interaction between clipboard events and translation state.

### Gaps Summary

**All 5 functional truths are verified** — the pivot translation implementation is complete and correctly wired. The production code in `PopupView.swift` and `TranslationErrorMapper.swift` fully delivers PIV-01, PIV-02, and PIV-03.

**All test gaps closed:**

1. **TranslationErrorMapperTests.swift** — Created with 8 tests covering `isPivotTrigger` and `message(for:)` (commit 458f0d5).

2. **TranslationTaskConfigurationReloaderTests.swift** — Updated with 2 pivot configuration tests verifying explicit EN source and non-nil source for D-02 (commit 458f0d5).

**Implementation deviations (non-blocking):** The PLAN specified a `PivotTranslationState` type and function name `isUnsupportedPairError`. The implementation chose individual `@State` vars and `isPivotTrigger` as the function name. These are naming/architecture deviations that don't affect correctness — the Summary documents the Swift 6 concurrency reasons for the architectural change.

**Root cause (historical):** The initial execution prioritized resolving Swift 6 strict concurrency issues, deferring test creation. Tests were added in the gap closure commit (458f0d5).

---

_Verified: 2026-04-17T23:35:00+09:00_
_Verifier: the agent (gsd-verifier)_

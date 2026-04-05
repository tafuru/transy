# Phase 14: Shimmer Animation - Context

## Domain Boundary

Add an animated shimmer overlay to the translation loading state in `LoadingPopupText`. This is a visual-only feature — no translation logic, no state machine changes, no new API calls.

## Decisions

### Shimmer Visual Style
**Decision:** Gradient sweep — a highlight band that travels left→right across the text, standard iOS/macOS skeleton animation pattern.

### Shimmer Scope
**Decision:** Text area overlay only. The shimmer gradient covers the text content within `PopupText`, preserving the popup's `.regularMaterial` rounded background as-is. This is critical for SHM-02 (zero-layout-impact) — the overlay must not alter the `GeometryReader`-based height measurement in `PopupText`.

### Blend Mode
**Decision:** `.plusLighter` blend mode. Adds light to whatever is underneath, automatically adapting to both light and dark system appearances without needing separate color variants.

### Animation Timing
**Decision:** 1.5-second sweep duration from left to right edge. Uses `.linear(duration: 1.5).repeatForever(autoreverses: false)` — continuous loop with no pause between sweeps.

### Reduce Motion Fallback
**Decision:** When `accessibilityReduceMotion` is enabled, no animation plays. The loading state shows the current muted source text as-is (existing behavior). No static placeholder bar — just the dimmed text.

## Specifics

- The shimmer is a `ViewModifier` (new file: `ShimmerModifier.swift`) applied to the text content inside `LoadingPopupText`
- MUST NOT change layout dimensions — any size change fires `NSWindow.didResizeNotification` which repositions the NSPanel, causing visible jitter (the "resize notification storm" pitfall from PITFALLS.md)
- `@Environment(\.accessibilityReduceMotion)` drives the animation disable
- Shimmer starts when `LoadingPopupText` appears and stops when the view is replaced by result/error state (SwiftUI view lifecycle handles this — no manual start/stop)

## Deferred Ideas

None.

## Canonical Refs

- `.planning/research/PITFALLS.md` — Pitfall 1 (shimmer zero-layout-impact), Pitfall 2 (shimmer must be clipped)
- `.planning/research/ARCHITECTURE.md` — Shimmer architecture section
- `.planning/research/SUMMARY.md` — Overall confidence and phase ordering rationale
- `.planning/REQUIREMENTS.md` — SHM-01, SHM-02, SHM-03 definitions
- `Transy/Popup/PopupView.swift` — LoadingPopupText (lines 105-159), PopupText (lines 59-96)

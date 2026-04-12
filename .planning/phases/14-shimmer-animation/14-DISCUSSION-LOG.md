# Phase 14: Shimmer Animation — Discussion Log

**Date:** 2026-04-05
**Participants:** User, Agent

## Gray Areas Identified

1. Shimmer visual style — gradient sweep or pulsing opacity?
2. Shimmer scope — over text only or full popup area?
3. Color / blend mode — how does the gradient interact with the dark/light material?
4. Timing / speed — how fast does the band sweep?
5. Reduce Motion fallback — what does the static state look like?

## Areas Selected for Discussion

- Shimmer visual style
- Color / blend mode
- Shimmer timing / speed
- Reduce Motion fallback

(Shimmer scope was decided within the visual style discussion)

## Discussion

### 1. Shimmer Visual Style

**Q:** How should the shimmer animate? The loading state currently shows the source text dimmed (muted). The shimmer overlays on top of that.
- Options: Gradient sweep (left→right band), Pulsing opacity, You decide
- **Selected:** Gradient sweep — standard iOS/macOS skeleton style

**Q:** Should the shimmer gradient sweep over just the text, or the entire popup background?
- Options: Text content only (recommended), Entire popup surface
- **Selected:** Text content only — preserves rounded background, zero-layout-impact

### 2. Color / Blend Mode

**Q:** How should the shimmer gradient blend with the popup's material background?
- Options: `.plusLighter` blend mode (recommended), White/gray gradient at low opacity, You decide
- **Selected:** `.plusLighter` — adapts to both light/dark mode automatically

### 3. Shimmer Timing / Speed

**Q:** How long does one sweep take (left edge → right edge)?
- Options: 1.5s (recommended), 1.0s, 2.0s
- **Selected:** 1.5 seconds — standard skeleton animation tempo

**Q:** Loop interval between sweeps?
- Options: No pause (recommended), Short 0.3s pause
- **Selected:** No pause — continuous loop (`repeatForever(autoreverses: false)`)

### 4. Reduce Motion Fallback

**Q:** When Reduce Motion is enabled, what should the loading state show?
- Options: Muted source text as-is (recommended), Static gray bar placeholder
- **Selected:** Muted source text — keep current behavior, no animation

## Decisions Summary

| Area | Decision |
|------|----------|
| Visual style | Gradient sweep (left→right highlight band) |
| Scope | Text area overlay only |
| Blend mode | `.plusLighter` (light/dark adaptive) |
| Speed | 1.5s per sweep, continuous loop |
| Reduce Motion | Current muted text (no animation) |

---
*Log generated: 2026-04-05*

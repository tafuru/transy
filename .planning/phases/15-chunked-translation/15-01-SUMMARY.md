---
phase: 15-chunked-translation
plan: 01
subsystem: translation
tags: [NLTokenizer, sentence-splitting, text-processing]

requires: []
provides:
  - "TextChunker.chunk(text:threshold:) → [ChunkedSegment] API for sentence-boundary splitting"
  - "Roundtrip-safe separator recording between chunks"
affects: [15-02, translation-pipeline]

tech-stack:
  added: []
  patterns: ["enum namespace with static methods (matches TextNormalization)"]

key-files:
  created:
    - Transy/Translation/TextChunker.swift
    - TransyTests/TextChunkerTests.swift
  modified: []

key-decisions:
  - "Greedy sentence grouping: pack as many sentences as fit within threshold"
  - "Separator = gap between NLTokenizer ranges, not hardcoded delimiter"

patterns-established:
  - "TDD cycle: stub → 9 failing tests → implement → all GREEN"
  - "ChunkedSegment(chunk:separator:) as data contract for chunked translation"

requirements-completed: [CHK-01, CHK-03]

duration: 5min
completed: 2026-04-12
---

# Plan 15-01: TextChunker TDD Summary

**NLTokenizer sentence-boundary splitter with greedy grouping, separator recording, and 9-test TDD suite**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-04-12T22:56:00Z
- **Completed:** 2026-04-12T23:06:00Z
- **Tasks:** 2 (RED → GREEN)
- **Files modified:** 3

## Accomplishments
- TextChunker enum namespace with `chunk(text:threshold:)` static method
- Short-text bypass (≤200 chars) skips NLTokenizer entirely (CHK-03)
- Sentence-boundary splitting via NLTokenizer `.sentence` unit (CHK-01)
- Greedy grouping keeps chunks within threshold
- Separator recording preserves original whitespace/newlines between chunks
- Empty/whitespace-only chunk filtering (Pitfall 8)
- Roundtrip invariant: `chunks + separators == original text`
- 9 comprehensive tests all passing

## Task Commits

1. **Task 1: RED — TextChunker stub + test suite** - `4fbb431` (test)
2. **Task 2: GREEN — Full implementation** - `ff7f23f` (feat)

## Files Created/Modified
- `Transy/Translation/TextChunker.swift` — enum namespace with ChunkedSegment struct and chunk() method
- `TransyTests/TextChunkerTests.swift` — 9 tests covering all edge cases

## Decisions Made
None — followed plan as specified.

## Deviations from Plan
None — plan executed exactly as written.

## Issues Encountered
None.

## Next Phase Readiness
- TextChunker API ready for Plan 15-02 to wire into PopupView
- `[ChunkedSegment]` is Sendable — safe for nonisolated closure capture

---
*Phase: 15-chunked-translation*
*Completed: 2026-04-12*

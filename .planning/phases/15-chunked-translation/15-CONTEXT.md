# Phase 15: Chunked Translation — Context

## Domain Boundary

Texts longer than 200 characters are split at sentence boundaries via NLTokenizer and translated as a single batch call, returning a correctly ordered result. Texts ≤200 characters bypass chunking entirely.

## Decisions

### Chunking Threshold
- **200 characters fixed** — no dynamic adjustment
- NLTokenizer `.sentence` unit for boundary detection
- Sentences are grouped into chunks of ≤200 characters each (chunk = multiple sentences)
- This reduces the number of batch requests compared to one-request-per-sentence

### Short-Text Bypass (CHK-03)
- **NLTokenizer is completely skipped** for ≤200 char texts
- Character count check only, then `session.translate()` directly (current code path unchanged)
- Zero overhead for short texts

### Batch API Choice
- **`translations(from: [TranslationSession.Request])`** — returns `[Response]` in input order
- NOT `translate(batch:)` (AsyncThrowingStream, unordered) — per Pitfall 4
- All chunks submitted as one batch call, results returned all at once

### Error Handling
- **Fail entire translation on any error** — no partial results
- The batch API is all-or-nothing, so this aligns naturally
- Existing `TranslationErrorMapper` handles the error display

### Whitespace & Separator Preservation
- **Separator recording approach** — record original text between chunk boundaries
- NLTokenizer returns `Range<String.Index>` — gaps between ranges are the separators
- TextChunker returns `[(chunk: String, separator: String)]` structure
- Joining: interleave translated chunks with original separators
- Preserves newlines, paragraph breaks, and indentation from source text

### Shimmer Integration
- **Shimmer stays as-is** — covers entire source text during loading
- No progressive display (translations(from:) returns all results at once)
- Shimmer stops when full translated result appears — same UX as current single-call path

### Code Placement
- **New file: `Transy/Translation/TextChunker.swift`** — enum namespace
- Separate from TextNormalization (different responsibility: NLTokenizer vs simple string ops)
- API: `TextChunker.chunk(text:threshold:) -> [ChunkedSegment]`
- Tests: `TransyTests/TextChunkerTests.swift`

### NLTokenizer Isolation (Pitfall 5)
- NLTokenizer must run on `@MainActor` (non-Sendable ObjC class in Swift 6)
- Chunking performed in `LoadingPopupText` (already on MainActor) BEFORE `translationAction` closure
- Chunk array (`[String]`, Sendable) captured in closure safely

## Specifics

- User explicitly chose separator recording over block-then-sentence splitting
- User confirmed that progressive streaming display is deferred (considered translate(batch:) but chose simplicity)
- User wants new file rather than expanding TextNormalization

## Deferred Ideas

- Progressive chunk display with `translate(batch:)` streaming — revisit in future milestone for richer UX

## Canonical Refs

- `.planning/research/PITFALLS.md` — Pitfalls 4, 5, 8 directly affect this phase
- `.planning/research/ARCHITECTURE.md` — batch API usage patterns
- `.planning/REQUIREMENTS.md` — CHK-01, CHK-02, CHK-03 definitions
- `Transy/Popup/PopupView.swift` — `LoadingPopupText`, `translationAction` (integration points)
- `Transy/Translation/TextNormalization.swift` — existing text processing pattern to follow
- `Transy/Translation/TranslationCoordinator.swift` — state machine (no changes needed)

import Testing
@testable import Transy

struct TextChunkerTests {
    @Test("short text bypass returns single segment without splitting")
    func shortTextBypass() {
        let result = TextChunker.chunk(text: "Hello world.", threshold: 200)
        #expect(result.count == 1)
        #expect(result.first?.chunk == "Hello world.")
        #expect(result.first?.separator == "")
    }

    @Test("text exactly at threshold returns single segment")
    func exactlyAtThreshold() {
        let text = String(repeating: "a", count: 200)
        let result = TextChunker.chunk(text: text, threshold: 200)
        #expect(result.count == 1)
        #expect(result.first?.chunk == text)
        #expect(result.first?.separator == "")
    }

    @Test("splits at sentence boundaries when text exceeds threshold")
    func splitsAtSentenceBoundaries() {
        let text = "The quick brown fox jumped. The lazy dog slept. The cat watched."
        let result = TextChunker.chunk(text: text, threshold: 30)
        #expect(result.count > 1)
        for segment in result {
            let trimmed = segment.chunk.trimmingCharacters(in: .whitespacesAndNewlines)
            #expect(!trimmed.isEmpty)
        }
    }

    @Test("roundtrip invariant: chunks + separators reconstruct original text")
    func roundtripInvariant() {
        let text = "First sentence here. Second sentence follows.\nThird on new line. Fourth is last."
        let result = TextChunker.chunk(text: text, threshold: 30)
        let reconstructed = result.map { $0.chunk + $0.separator }.joined()
        #expect(reconstructed == text)
    }

    @Test("paragraph breaks are preserved in roundtrip")
    func paragraphBreaksPreserved() {
        let text = "First paragraph.\n\nSecond paragraph."
        let result = TextChunker.chunk(text: text, threshold: 20)
        let reconstructed = result.map { $0.chunk + $0.separator }.joined()
        #expect(reconstructed == text)
        #expect(reconstructed.contains("\n\n"))
    }

    @Test("no whitespace-only chunks in output")
    func noWhitespaceOnlyChunks() {
        let text = "Line one.\n\n\nLine two."
        let result = TextChunker.chunk(text: text, threshold: 15)
        for segment in result {
            let trimmed = segment.chunk.trimmingCharacters(in: .whitespacesAndNewlines)
            #expect(!trimmed.isEmpty)
        }
    }

    @Test("default threshold is 200")
    func defaultThreshold() {
        let shortText = "Short text."
        let result = TextChunker.chunk(text: shortText)
        #expect(result.count == 1)
        #expect(result.first?.chunk == shortText)
    }

    @Test("single sentence over threshold returns exactly one segment")
    func singleSentenceOverThreshold() {
        let text = String(repeating: "word ", count: 50) + "end."
        let result = TextChunker.chunk(text: text)
        #expect(result.count == 1)
        #expect(result.first?.chunk == text)
    }

    @Test("sentences grouped within threshold returns single segment")
    func sentencesGroupedWithinThreshold() {
        let text = "Short. Also short. Tiny."
        let result = TextChunker.chunk(text: text, threshold: 200)
        #expect(result.count == 1)
        #expect(result.first?.chunk == text)
    }
}

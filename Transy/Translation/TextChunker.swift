import NaturalLanguage

enum TextChunker {
    struct ChunkedSegment: Sendable, Equatable {
        let chunk: String
        let separator: String
    }

    static func chunk(
        text: String,
        threshold: Int = 200
    ) -> [ChunkedSegment] {
        guard text.count > threshold else {
            return [ChunkedSegment(chunk: text, separator: "")]
        }

        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text

        var allRanges: [Range<String.Index>] = []
        tokenizer.enumerateTokens(in: text.startIndex ..< text.endIndex) { range, _ in
            allRanges.append(range)
            return true
        }

        // Filter whitespace-only "sentences" (NLTokenizer treats blank lines as sentences).
        // Keeping only real sentences ensures blank lines fall into inter-range gaps (separators).
        let sentenceRanges = allRanges.filter { range in
            !text[range].allSatisfy(\.isWhitespace)
        }

        guard !sentenceRanges.isEmpty else {
            return [ChunkedSegment(chunk: text, separator: "")]
        }

        var groups: [(first: Range<String.Index>, last: Range<String.Index>)] = []
        var groupFirst = sentenceRanges[0]
        var groupLast = sentenceRanges[0]

        for i in 1 ..< sentenceRanges.count {
            let candidate = sentenceRanges[i]
            let spanLength = text.distance(from: groupFirst.lowerBound, to: candidate.upperBound)
            if spanLength <= threshold {
                groupLast = candidate
            } else {
                groups.append((first: groupFirst, last: groupLast))
                groupFirst = candidate
                groupLast = candidate
            }
        }
        groups.append((first: groupFirst, last: groupLast))

        var segments: [ChunkedSegment] = []
        for (index, group) in groups.enumerated() {
            var chunkText = String(text[group.first.lowerBound ..< group.last.upperBound])

            let separatorEnd: String.Index
            if index + 1 < groups.count {
                separatorEnd = groups[index + 1].first.lowerBound
            } else {
                separatorEnd = text.endIndex
            }
            var separator = String(text[group.last.upperBound ..< separatorEnd])

            // Move trailing whitespace from chunk to separator so translation
            // cannot strip newlines that separate paragraphs.
            let trimmedChunk = chunkText.replacingOccurrences(
                of: "\\s+$", with: "", options: .regularExpression
            )
            if trimmedChunk.count < chunkText.count {
                let trailingWS = String(chunkText[chunkText.index(chunkText.startIndex, offsetBy: trimmedChunk.count)...])
                separator = trailingWS + separator
                chunkText = trimmedChunk
            }

            segments.append(ChunkedSegment(chunk: chunkText, separator: separator))
        }

        // Handle leading whitespace before first sentence
        if let firstRange = sentenceRanges.first,
           firstRange.lowerBound > text.startIndex,
           !segments.isEmpty {
            let leading = String(text[text.startIndex ..< firstRange.lowerBound])
            segments[0] = ChunkedSegment(
                chunk: leading + segments[0].chunk,
                separator: segments[0].separator
            )
        }

        if segments.isEmpty {
            return [ChunkedSegment(chunk: text, separator: "")]
        }

        return segments
    }
}

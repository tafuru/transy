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

        var sentenceRanges: [Range<String.Index>] = []
        tokenizer.enumerateTokens(in: text.startIndex ..< text.endIndex) { range, _ in
            sentenceRanges.append(range)
            return true
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
            let chunkText = String(text[group.first.lowerBound ..< group.last.upperBound])

            if chunkText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                continue
            }

            let separatorEnd: String.Index
            if index + 1 < groups.count {
                separatorEnd = groups[index + 1].first.lowerBound
            } else {
                separatorEnd = text.endIndex
            }
            let separator = String(text[group.last.upperBound ..< separatorEnd])

            segments.append(ChunkedSegment(chunk: chunkText, separator: separator))
        }

        if segments.isEmpty {
            return [ChunkedSegment(chunk: text, separator: "")]
        }

        return segments
    }
}

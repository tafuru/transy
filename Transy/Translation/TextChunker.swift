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
        []
    }
}

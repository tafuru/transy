import Foundation

enum TextNormalization {
    /// Trims leading/trailing whitespace and newlines from source text.
    static func normalized(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Produces a compact, whitespace-collapsed sample suitable for language detection.
    static func detectionSample(from text: String) -> String {
        normalized(text)
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }
}

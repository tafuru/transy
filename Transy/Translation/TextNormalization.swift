import Foundation

func normalizedSourceText(_ text: String) -> String {
    text.trimmingCharacters(in: .whitespacesAndNewlines)
}

func detectionSample(from text: String) -> String {
    normalizedSourceText(text)
        .split(whereSeparator: \.isWhitespace)
        .joined(separator: " ")
}

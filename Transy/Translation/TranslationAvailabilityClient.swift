import Foundation
import Translation

final class TranslationAvailabilityClient {
    enum PreflightResult: Equatable, Sendable {
        case ready
        case unavailable(message: String)
    }

    typealias StatusProvider = @Sendable (_ sampleText: String, _ targetLanguage: Locale.Language) async throws -> LanguageAvailability.Status

    let targetLanguage: Locale.Language

    private let statusProvider: StatusProvider

    init(
        targetLanguage: Locale.Language = Locale.Language(identifier: "en"),
        statusProvider: StatusProvider? = nil
    ) {
        self.targetLanguage = targetLanguage
        self.statusProvider = statusProvider ?? Self.liveStatus
    }

    func preflight(for sourceText: String) async throws -> PreflightResult {
        let sampleText = detectionSample(from: sourceText)
        guard !sampleText.isEmpty else {
            return .unavailable(message: TranslationErrorMapper.couldNotDetectSourceLanguage)
        }

        do {
            let status = try await statusProvider(sampleText, targetLanguage)
            switch status {
            case .installed:
                return .ready
            case .supported:
                return .unavailable(message: TranslationErrorMapper.modelNotInstalled)
            case .unsupported:
                return .unavailable(message: TranslationErrorMapper.unsupportedLanguagePair)
            @unknown default:
                return .unavailable(message: TranslationErrorMapper.translationFailed)
            }
        } catch {
            return .unavailable(message: TranslationErrorMapper.message(for: error))
        }
    }

    private static func liveStatus(
        sampleText: String,
        targetLanguage: Locale.Language
    ) async throws -> LanguageAvailability.Status {
        let availability = LanguageAvailability()
        return try await availability.status(for: sampleText, to: targetLanguage)
    }
}

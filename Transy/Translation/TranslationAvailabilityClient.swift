import Foundation
import Translation

struct TranslationAvailabilityClient {
    enum PreflightResult: Equatable {
        case ready
        case unsupported
        case couldNotDetect
        case failed(message: String)
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
        let sampleText = TextNormalization.detectionSample(from: sourceText)
        guard !sampleText.isEmpty else {
            return .couldNotDetect
        }

        do {
            let status = try await statusProvider(sampleText, targetLanguage)
            switch status {
            case .installed, .supported:
                return .ready
            case .unsupported:
                return .unsupported
            @unknown default:
                return .failed(message: TranslationErrorMapper.translationFailed)
            }
        } catch let error as CancellationError {
            throw error
        } catch {
            return .failed(message: TranslationErrorMapper.message(for: error))
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

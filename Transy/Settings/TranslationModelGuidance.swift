import Foundation
import Translation

/// Conditional guidance for missing Apple Translation models.
/// Returns none before relevance, generic after a real missing-model event with unknown pair
/// certainty, and only pair-specific when trusted known-pair context is explicitly available.
struct TranslationModelGuidance {
    enum GuidanceState: Equatable {
        case none
        case generic
        case pairSpecific(source: Locale.Language, target: Locale.Language)
    }

    private let missingModelContext: MissingModelContext?
    private let statusProvider: (@Sendable (Locale.Language, Locale.Language) async throws -> LanguageAvailability.Status)?

    init(
        missingModelContext: MissingModelContext?,
        statusProvider: (@Sendable (Locale.Language, Locale.Language) async throws -> LanguageAvailability.Status)? = nil
    ) {
        self.missingModelContext = missingModelContext
        self.statusProvider = statusProvider
    }

    func currentState() async -> GuidanceState {
        guard let context = missingModelContext else {
            return .none
        }

        // If we have a known source language, check if the pair is actually supported
        if let knownSource = context.knownSourceLanguage {
            do {
                let provider = statusProvider ?? Self.liveStatusProvider
                let status = try await provider(knownSource, context.targetLanguage)

                // Only show pair-specific guidance if the model is actually supported
                if status == .supported {
                    return .pairSpecific(source: knownSource, target: context.targetLanguage)
                }

                // If installed or unsupported, no guidance needed
                return .none
            } catch {
                // If status check fails, fall back to generic
                return .generic
            }
        }

        // No known source language, show generic guidance
        return .generic
    }

    private static let liveStatusProvider:
        @Sendable (Locale.Language, Locale.Language) async throws -> LanguageAvailability.Status = { source, target in
            let availability = LanguageAvailability()
            return try await availability.status(from: source, to: target)
        }
}

/// Context about missing-model relevance recorded from real runtime outcomes.
struct MissingModelContext: Equatable {
    let targetLanguage: Locale.Language
    let knownSourceLanguage: Locale.Language?

    init(targetLanguage: Locale.Language, knownSourceLanguage: Locale.Language? = nil) {
        self.targetLanguage = targetLanguage
        self.knownSourceLanguage = knownSourceLanguage
    }
}

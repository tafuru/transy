import Testing
import Translation
@testable import Transy

struct TranslationModelGuidanceTests {
    @Test("Guidance is none before any missing-model-relevant runtime state exists")
    func noGuidanceBeforeRelevance() async {
        let guidance = TranslationModelGuidance(missingModelContext: nil)

        let state = await guidance.currentState()

        #expect(state == .none)
    }

    @Test("Guidance is generic after a missing-model event with unknown pair certainty")
    func genericGuidanceAfterMissingModelWithUnknownPair() async {
        let context = MissingModelContext(
            targetLanguage: Locale.Language(identifier: "ja"),
            knownSourceLanguage: nil
        )
        let guidance = TranslationModelGuidance(missingModelContext: context)

        let state = await guidance.currentState()

        #expect(state == .generic)
    }

    @Test("Guidance is pair-specific when trusted source context exists and status is supported")
    func pairSpecificGuidanceWhenKnownPairIsSupported() async {
        let sourceLanguage = Locale.Language(identifier: "en")
        let targetLanguage = Locale.Language(identifier: "ja")
        let context = MissingModelContext(
            targetLanguage: targetLanguage,
            knownSourceLanguage: sourceLanguage
        )

        // Mock status provider that returns .supported
        let mockStatusProvider: @Sendable (Locale.Language, Locale.Language) async throws -> LanguageAvailability.Status = { _, _ in
            .supported
        }

        let guidance = TranslationModelGuidance(
            missingModelContext: context,
            statusProvider: mockStatusProvider
        )

        let state = await guidance.currentState()

        #expect(state == .pairSpecific(source: sourceLanguage, target: targetLanguage))
    }

    @Test("Guidance is none when status is installed")
    func noGuidanceWhenModelIsInstalled() async {
        let sourceLanguage = Locale.Language(identifier: "en")
        let targetLanguage = Locale.Language(identifier: "ja")
        let context = MissingModelContext(
            targetLanguage: targetLanguage,
            knownSourceLanguage: sourceLanguage
        )

        // Mock status provider that returns .installed
        let mockStatusProvider: @Sendable (Locale.Language, Locale.Language) async throws -> LanguageAvailability.Status = { _, _ in
            .installed
        }

        let guidance = TranslationModelGuidance(
            missingModelContext: context,
            statusProvider: mockStatusProvider
        )

        let state = await guidance.currentState()

        #expect(state == .none)
    }

    @Test("Guidance is none when status is unsupported")
    func noGuidanceWhenPairIsUnsupported() async {
        let sourceLanguage = Locale.Language(identifier: "en")
        let targetLanguage = Locale.Language(identifier: "fake")
        let context = MissingModelContext(
            targetLanguage: targetLanguage,
            knownSourceLanguage: sourceLanguage
        )

        // Mock status provider that returns .unsupported
        let mockStatusProvider: @Sendable (Locale.Language, Locale.Language) async throws -> LanguageAvailability.Status = { _, _ in
            .unsupported
        }

        let guidance = TranslationModelGuidance(
            missingModelContext: context,
            statusProvider: mockStatusProvider
        )

        let state = await guidance.currentState()

        #expect(state == .none)
    }
}

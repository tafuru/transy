import Testing
import Translation
@testable import Transy

struct TranslationErrorMapperTests {
    // MARK: - isPivotTrigger

    @Test("unsupportedLanguagePairing triggers pivot")
    func unsupportedLanguagePairingTriggersPivot() {
        #expect(TranslationErrorMapper.isPivotTrigger(TranslationError.unsupportedLanguagePairing))
    }

    @Test("unsupportedSourceLanguage triggers pivot")
    func unsupportedSourceLanguageTriggersPivot() {
        #expect(TranslationErrorMapper.isPivotTrigger(TranslationError.unsupportedSourceLanguage))
    }

    @Test("unsupportedTargetLanguage triggers pivot")
    func unsupportedTargetLanguageTriggersPivot() {
        #expect(TranslationErrorMapper.isPivotTrigger(TranslationError.unsupportedTargetLanguage))
    }

    @Test("unableToIdentifyLanguage does not trigger pivot")
    func unableToIdentifyLanguageDoesNotTriggerPivot() {
        #expect(!TranslationErrorMapper.isPivotTrigger(TranslationError.unableToIdentifyLanguage))
    }

    @Test("generic error does not trigger pivot")
    func genericErrorDoesNotTriggerPivot() {
        struct SomeError: Error {}
        #expect(!TranslationErrorMapper.isPivotTrigger(SomeError()))
    }

    // MARK: - message(for:) mapping

    @Test("unsupported pairing maps to unsupportedLanguagePair message")
    func unsupportedPairingMessage() {
        let message = TranslationErrorMapper.message(for: TranslationError.unsupportedLanguagePairing)
        #expect(message == TranslationErrorMapper.unsupportedLanguagePair)
    }

    @Test("unableToIdentifyLanguage maps to detection failure message")
    func detectionFailureMessage() {
        let message = TranslationErrorMapper.message(for: TranslationError.unableToIdentifyLanguage)
        #expect(message == TranslationErrorMapper.couldNotDetectSourceLanguage)
    }

    @Test("unknown error maps to generic failure message")
    func unknownErrorMessage() {
        struct UnknownError: Error {}
        #expect(TranslationErrorMapper.message(for: UnknownError()) == TranslationErrorMapper.translationFailed)
    }
}

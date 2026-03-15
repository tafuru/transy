import Foundation
import Testing
import Translation
@testable import Transy

@Suite("Translation task configuration reloader")
struct TranslationTaskConfigurationReloaderTests {

    @Test("first configuration uses auto-detected source and requested target")
    func firstConfigurationUsesAutoDetectedSource() {
        let targetLanguage = Locale.Language(identifier: "en")

        let configuration = nextTranslationConfiguration(
            after: nil,
            targetLanguage: targetLanguage
        )

        #expect(configuration.source == nil)
        #expect(configuration.target == targetLanguage)
    }

    @Test("subsequent configuration invalidates previous translation session")
    func subsequentConfigurationInvalidatesPriorSession() {
        let targetLanguage = Locale.Language(identifier: "en")
        let initialConfiguration = nextTranslationConfiguration(
            after: nil,
            targetLanguage: targetLanguage
        )

        let nextConfiguration = nextTranslationConfiguration(
            after: initialConfiguration,
            targetLanguage: targetLanguage
        )

        #expect(nextConfiguration.source == nil)
        #expect(nextConfiguration.target == targetLanguage)
        #expect(nextConfiguration.version > initialConfiguration.version)
    }
}

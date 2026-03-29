import Foundation
import Testing
import Translation
@testable import Transy

struct TranslationConfigReloaderTests {
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

    @Test("popup dismiss tears down hosted content so translationTask can cancel immediately")
    @MainActor
    func popupDismissRemovesHostedContent() throws {
        let controller = PopupController()
        let coordinator = TranslationCoordinator()
        _ = coordinator.begin(sourceText: "とても長い原文です")

        let mockClient = TranslationAvailabilityClient(targetLanguage: Locale.Language(identifier: "en"))
        let settingsSuiteName = "test-\(UUID())"
        let settingsDefaults = try #require(UserDefaults(suiteName: settingsSuiteName))
        defer { settingsDefaults.removePersistentDomain(forName: settingsSuiteName) }
        let mockSettingsStore = SettingsStore(
            userDefaults: settingsDefaults,
            preferredLanguageResolver: { Locale.Language(identifier: "en") }
        )
        controller.show(
            translationCoordinator: coordinator,
            availabilityClient: mockClient,
            settingsStore: mockSettingsStore
        ) {}

        #expect(controller.hasHostedPopupContent)

        controller.dismiss()

        #expect(!controller.hasHostedPopupContent)
    }
}

import Foundation
import Testing
@testable import Transy

/// Wave 0 coverage for first-run defaulting and persistence.
@MainActor
struct SettingsStoreTests {
    /// Test 1: First run resolves the default target language from an injected OS-preferred-language
    /// seam and persists that minimalIdentifier into UserDefaults.
    @Test("First run persists OS preferred language to UserDefaults")
    func firstRunPersistsPreferredLanguage() throws {
        let suiteName = "test.first-run.\(UUID().uuidString)"
        let mockDefaults = try #require(UserDefaults(suiteName: suiteName))
        defer { mockDefaults.removePersistentDomain(forName: suiteName) }

        let mockPreferredLanguage = Locale.Language(identifier: "ja")
        let resolver = { mockPreferredLanguage }

        let store = SettingsStore(userDefaults: mockDefaults, preferredLanguageResolver: resolver)

        // Verify the store resolved from the injected preferred language
        #expect(store.targetLanguage == mockPreferredLanguage)

        // Verify it was persisted to UserDefaults
        let storedIdentifier = mockDefaults.string(forKey: "targetLanguage")
        #expect(storedIdentifier == mockPreferredLanguage.minimalIdentifier)
    }

    /// Test 2: Once a stored target exists, later changes in the injected OS-preferred-language
    /// seam do not overwrite it.
    @Test("Stored target language is not overwritten by later OS preference changes")
    func storedTargetNotOverwrittenByPreferenceChanges() throws {
        let suiteName = "test.stored-value.\(UUID().uuidString)"
        let mockDefaults = try #require(UserDefaults(suiteName: suiteName))
        defer { mockDefaults.removePersistentDomain(forName: suiteName) }

        // First run: store French
        let firstResolver = { Locale.Language(identifier: "fr") }
        let firstStore = SettingsStore(userDefaults: mockDefaults, preferredLanguageResolver: firstResolver)
        #expect(firstStore.targetLanguage.minimalIdentifier == "fr")

        // Second initialization: OS preference changed to Japanese, but stored value should win
        let secondResolver = { Locale.Language(identifier: "ja") }
        let secondStore = SettingsStore(userDefaults: mockDefaults, preferredLanguageResolver: secondResolver)

        // Verify the stored French value is kept, not overwritten by Japanese
        #expect(secondStore.targetLanguage.minimalIdentifier == "fr")
    }
}

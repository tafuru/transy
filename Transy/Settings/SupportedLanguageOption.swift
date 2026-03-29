import Foundation
import Translation

/// Represents a supported target language option with a localized display name.
struct SupportedLanguageOption: Identifiable, Hashable {
    let id: String
    let language: Locale.Language
    let displayName: String

    init(language: Locale.Language) {
        self.id = language.minimalIdentifier
        self.language = language
        self.displayName = Locale.current.localizedString(
            forIdentifier: language.minimalIdentifier
        ) ?? language.minimalIdentifier
    }

    /// Load all supported target languages from Apple's Translation framework.
    static func loadSupportedLanguages() async -> [Self] {
        let availability = LanguageAvailability()
        let supportedLanguages = await availability.supportedLanguages

        return supportedLanguages
            .map { Self(language: $0) }
            .sorted { $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending }
    }
}

import Foundation
import Observation

/// Shared persisted target-language source of truth. Owned by AppDelegate, injected into Settings.
/// Persists only the minimalIdentifier; reconstructs Locale.Language from storage on read.
@MainActor
@Observable
final class SettingsStore {
    private let userDefaults: UserDefaults
    private let preferredLanguageResolver: () -> Locale.Language

    private static let targetLanguageKey = "targetLanguage"

    var targetLanguage: Locale.Language {
        didSet {
            persistTargetLanguage()
        }
    }

    /// Missing-model context recorded from real runtime outcomes.
    /// nil = no relevant runtime state yet; non-nil = a missing-model event occurred.
    private(set) var missingModelContext: MissingModelContext?

    init(
        userDefaults: UserDefaults = .standard,
        preferredLanguageResolver: (() -> Locale.Language)? = nil
    ) {
        self.userDefaults = userDefaults
        self.preferredLanguageResolver = preferredLanguageResolver ?? Self.defaultPreferredLanguageResolver

        // Load stored target or resolve from OS preferred language on first run
        if let storedIdentifier = userDefaults.string(forKey: Self.targetLanguageKey),
           !storedIdentifier.isEmpty {
            self.targetLanguage = Locale.Language(identifier: storedIdentifier)
        } else {
            self.targetLanguage = self.preferredLanguageResolver()
            persistTargetLanguage()
        }
    }

    func updateTargetLanguage(_ newLanguage: Locale.Language) {
        targetLanguage = newLanguage
    }

    func snapshotTargetLanguage() -> Locale.Language {
        targetLanguage
    }

    /// Record a missing-model event from a real runtime outcome.
    /// Called from popup/runtime when preflight returns .missingModel.
    func recordMissingModel(
        targetLanguage: Locale.Language,
        knownSourceLanguage: Locale.Language? = nil
    ) {
        missingModelContext = MissingModelContext(
            targetLanguage: targetLanguage,
            knownSourceLanguage: knownSourceLanguage
        )
    }

    private func persistTargetLanguage() {
        userDefaults.set(targetLanguage.minimalIdentifier, forKey: Self.targetLanguageKey)
    }

    private static func defaultPreferredLanguageResolver() -> Locale.Language {
        if let preferredLanguage = Locale.preferredLanguages.first {
            return Locale.Language(identifier: preferredLanguage)
        }
        return Locale.Language(identifier: "en")
    }
}

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
    
    init(
        userDefaults: UserDefaults = .standard,
        preferredLanguageResolver: (() -> Locale.Language)? = nil
    ) {
        self.userDefaults = userDefaults
        self.preferredLanguageResolver = preferredLanguageResolver ?? Self.defaultPreferredLanguageResolver
        
        // Load stored target or resolve from OS preferred language on first run
        let resolver = preferredLanguageResolver ?? Self.defaultPreferredLanguageResolver
        
        if let storedIdentifier = userDefaults.string(forKey: Self.targetLanguageKey),
           !storedIdentifier.isEmpty {
            self.targetLanguage = Locale.Language(identifier: storedIdentifier)
        } else {
            self.targetLanguage = resolver()
            persistTargetLanguage()
        }
    }
    
    func updateTargetLanguage(_ newLanguage: Locale.Language) {
        targetLanguage = newLanguage
    }
    
    func snapshotTargetLanguage() -> Locale.Language {
        targetLanguage
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

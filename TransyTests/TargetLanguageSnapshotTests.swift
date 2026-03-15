import Testing
import Foundation
@testable import Transy

/// Wave 0 coverage for request snapshot behavior.
@MainActor
struct TargetLanguageSnapshotTests {
    
    // Test 3: A request snapshot captured before updateTargetLanguage(_:) keeps the old target,
    // while a new snapshot taken after the update sees the new target.
    @Test("Request snapshot freezes target language at capture time")
    func snapshotFreezesTargetLanguage() async {
        let mockDefaults = UserDefaults(suiteName: "test.snapshot.\(UUID().uuidString)")!
        defer { mockDefaults.removePersistentDomain(forName: "test.snapshot") }
        
        let initialResolver = { Locale.Language(identifier: "en") }
        let store = SettingsStore(userDefaults: mockDefaults, preferredLanguageResolver: initialResolver)
        
        // Capture snapshot before update
        let snapshotBefore = store.snapshotTargetLanguage()
        #expect(snapshotBefore.minimalIdentifier == "en")
        
        // Update the store to a new target language
        store.updateTargetLanguage(Locale.Language(identifier: "fr"))
        
        // The earlier snapshot should still hold English (frozen at capture time)
        #expect(snapshotBefore.minimalIdentifier == "en")
        
        // A new snapshot after the update should see French
        let snapshotAfter = store.snapshotTargetLanguage()
        #expect(snapshotAfter.minimalIdentifier == "fr")
        
        // Verify the store itself now shows French
        #expect(store.targetLanguage.minimalIdentifier == "fr")
    }
}

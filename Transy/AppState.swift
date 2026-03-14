import Observation

/// Central app-state coordinator. Grows in later phases to hold trigger state,
/// popup visibility, and settings. Injected via SwiftUI environment from TransyApp.
@MainActor
@Observable
final class AppState {
    // Phase 2: var isPopupVisible = false
    // Phase 2: var triggerMonitor: HotkeyMonitor?
    // Phase 3: var translationTask: Task<Void, Never>?
    // Phase 4: var targetLanguage: Locale.Language = .init(identifier: "en")
}

import Observation

/// Central app-state coordinator. Grows in later phases to hold translation state and settings.
/// Injected via SwiftUI environment from TransyApp.
@MainActor
@Observable
final class AppState {
    var isPopupVisible: Bool = false
    // Phase 3: var translationTask: Task<Void, Never>?
    // Phase 4: var targetLanguage: Locale.Language = .init(identifier: "en")
}

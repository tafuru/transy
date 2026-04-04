import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let appState = AppState()
    let settingsStore = SettingsStore()
    private let clipboardMonitor = ClipboardMonitor()
    private let popupController = PopupController()
    private let translationCoordinator = TranslationCoordinator()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        clipboardMonitor.start { [weak self] text in
            self?.handleTrigger(text: text)
        }
    }

    // MARK: - Trigger flow

    private func handleTrigger(text: String) {
        let normalizedText = TextNormalization.normalized(text)
        guard !normalizedText.isEmpty else { return }

        _ = translationCoordinator.begin(sourceText: normalizedText)
        appState.isPopupVisible = true

        let targetLanguage = settingsStore.snapshotTargetLanguage()

        popupController.show(
            translationCoordinator: translationCoordinator,
            targetLanguage: targetLanguage
        ) { [weak self] in
            guard let self else { return }
            self.translationCoordinator.dismiss()
            self.appState.isPopupVisible = false
        }
    }
}

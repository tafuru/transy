import AppKit
import ApplicationServices

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let appState = AppState()
    let settingsStore = SettingsStore()
    private let hotkeyMonitor = HotkeyMonitor()
    private let popupController = PopupController()
    private let clipboardManager = ClipboardManager()
    private let translationCoordinator = TranslationCoordinator()
    private var restoreSession = ClipboardRestoreSession()
    private var isMonitoring = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Belt-and-suspenders alongside LSUIElement in Info.plist (Phase 1 pattern)
        NSApp.setActivationPolicy(.accessory)

        // Show Accessibility guidance immediately if permission is missing.
        // GuidanceWindowController polls for trust changes and fires the
        // callback once the user grants access.
        GuidanceWindowController.shared.onPermissionGranted = { [weak self] in
            self?.startMonitoringIfNeeded()
        }

        // Proactively show guidance if AX is not trusted (no-op if already trusted).
        GuidanceWindowController.shared.showIfNeeded()

        startMonitoringIfNeeded()
    }

    private func startMonitoringIfNeeded() {
        guard !isMonitoring, AXIsProcessTrusted() else { return }

        hotkeyMonitor.start(onDoubleCmdC: { [weak self] preSnapshot in
            self?.handleTrigger(preSnapshot: preSnapshot)
        })
        isMonitoring = true
    }

    // MARK: - Trigger flow

    private func handleTrigger(preSnapshot: [NSPasteboardItem]) {
        // If permission was revoked after launch, show guidance and bail
        guard AXIsProcessTrusted() else {
            GuidanceWindowController.shared.showIfNeeded()
            return
        }

        // preSnapshot was captured by HotkeyMonitor at the moment of the FIRST Cmd+C press,
        // before the source app wrote the selected text to the clipboard. Using it here
        // ensures we restore the user's original clipboard (e.g., "AAA"), not the selection
        // that triggered the capture (e.g., "BBB").
        _ = restoreSession.snapshotForSession(preSnapshot)

        Task { @MainActor in
            // 80ms delay: source app processes keyDown and writes selection to NSPasteboard.
            // This delay is documented in STATE.md and confirmed by RESEARCH.md Pattern 3.
            try? await Task.sleep(for: .milliseconds(80))

            guard let text = clipboardManager.readSelectedText(), !text.isEmpty else {
                // Permissions are OK but nothing was captured — stay completely silent.
                // CONTEXT.md locked decision: "if permissions are fine but capture fails, stay silent"
                restoreClipboardIfNeeded()
                return
            }

            let normalizedText = normalizedSourceText(text)
            guard !normalizedText.isEmpty else {
                restoreClipboardIfNeeded()
                return
            }

            _ = translationCoordinator.begin(sourceText: normalizedText)
            appState.isPopupVisible = true

            // Snapshot target language at trigger time — frozen for this request
            let frozenTarget = settingsStore.snapshotTargetLanguage()
            let availabilityClient = TranslationAvailabilityClient(targetLanguage: frozenTarget)

            popupController.show(
                translationCoordinator: translationCoordinator,
                availabilityClient: availabilityClient,
                settingsStore: settingsStore
            ) { [weak self] in
                guard let self else { return }
                self.translationCoordinator.dismiss()
                self.appState.isPopupVisible = false
                self.restoreClipboardIfNeeded()
            }
        }
    }

    // MARK: - Clipboard restore

    private func restoreClipboardIfNeeded() {
        guard !appState.isPopupVisible,
              let restoreSnapshot = restoreSession.consumeRestoreSnapshot() else { return }
        clipboardManager.restore(restoreSnapshot)
    }
}

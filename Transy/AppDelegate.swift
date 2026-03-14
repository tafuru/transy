import AppKit
import ApplicationServices

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    private let appState = AppState()
    private let hotkeyMonitor = HotkeyMonitor()
    private let popupController = PopupController()
    private let clipboardManager = ClipboardManager()
    private var isMonitoring = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Belt-and-suspenders alongside LSUIElement in Info.plist (Phase 1 pattern)
        NSApp.setActivationPolicy(.accessory)

        // Do not show guidance on first launch. MenuBarView.onAppear is the explicit
        // fallback entry point when AX is missing. If the user later grants AX from
        // System Settings, GuidanceWindowController notifies us so monitoring can start.
        GuidanceWindowController.shared.onPermissionGranted = { [weak self] in
            self?.startMonitoringIfNeeded()
        }

        startMonitoringIfNeeded()
    }

    private func startMonitoringIfNeeded() {
        guard !isMonitoring, AXIsProcessTrusted() else { return }

        hotkeyMonitor.start(onDoubleCmdC: { [weak self] in
            self?.handleTrigger()
        })
        isMonitoring = true
    }

    // MARK: - Trigger flow

    private func handleTrigger() {
        // If permission was revoked after launch, show guidance and bail
        guard AXIsProcessTrusted() else {
            GuidanceWindowController.shared.showIfNeeded()
            return
        }

        // Save clipboard BEFORE source app writes the selection (timing is critical)
        let saved = clipboardManager.saveCurrentContents()

        Task { @MainActor in
            // 80ms delay: source app processes keyDown and writes selection to NSPasteboard.
            // This delay is documented in STATE.md and confirmed by RESEARCH.md Pattern 3.
            try? await Task.sleep(for: .milliseconds(80))

            guard let text = clipboardManager.readSelectedText(), !text.isEmpty else {
                // Permissions are OK but nothing was captured — stay completely silent.
                // CONTEXT.md locked decision: "if permissions are fine but capture fails, stay silent"
                clipboardManager.restore(saved)
                return
            }

            appState.isPopupVisible = true
            popupController.show(sourceText: text) { [weak self] in
                self?.appState.isPopupVisible = false
                self?.clipboardManager.restore(saved)
            }
        }
    }
}

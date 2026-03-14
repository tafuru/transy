import AppKit
import ApplicationServices

@MainActor
final class HotkeyMonitor {
    private var monitor: Any?
    private var detector = DoublePressDetector()
    private let clipboardManager = ClipboardManager()
    private var firstPressSnapshot: [NSPasteboardItem] = []
    private var onDoubleCmdC: (@MainActor ([NSPasteboardItem]) -> Void)?

    /// Start monitoring global Cmd+C events. The closure receives the clipboard snapshot
    /// taken at the moment of the **first** Cmd+C press — before the source app overwrites
    /// the clipboard with the selected text.
    func start(onDoubleCmdC: @escaping @MainActor ([NSPasteboardItem]) -> Void) {
        guard AXIsProcessTrusted() else { return }
        self.onDoubleCmdC = onDoubleCmdC
        monitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            MainActor.assumeIsolated {
                self?.handle(event)
            }
        }
    }

    func stop() {
        if let m = monitor {
            NSEvent.removeMonitor(m)
            monitor = nil
        }
        detector = DoublePressDetector()   // reset state on stop
        firstPressSnapshot = []
        onDoubleCmdC = nil
    }

    private func handle(_ event: NSEvent) {
        // Filter: must be exactly Cmd+C (keyCode 8), no other modifiers, no key-repeat
        guard event.modifierFlags.intersection(.deviceIndependentFlagsMask) == .command,
              event.keyCode == 8,
              !event.isARepeat else { return }

        switch detector.record() {
        case .firstPress:
            // Snapshot the clipboard NOW, before the source app processes this Cmd+C and
            // overwrites the clipboard with the selected text.
            firstPressSnapshot = clipboardManager.saveCurrentContents()
        case .doublePress:
            // Pass the pre-copy snapshot so the caller can restore the original clipboard.
            let snapshot = firstPressSnapshot
            firstPressSnapshot = []
            onDoubleCmdC?(snapshot)
        }
    }
}

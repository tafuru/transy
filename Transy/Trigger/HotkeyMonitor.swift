import AppKit
import ApplicationServices

@MainActor
final class HotkeyMonitor {
    private var monitor: Any?
    private var detector = DoublePressDetector()
    private var onDoubleCmdC: (@MainActor () -> Void)?

    func start(onDoubleCmdC: @escaping @MainActor () -> Void) {
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
        onDoubleCmdC = nil
    }

    private func handle(_ event: NSEvent) {
        // Filter: must be exactly Cmd+C (keyCode 8), no other modifiers, no key-repeat
        guard event.modifierFlags.intersection(.deviceIndependentFlagsMask) == .command,
              event.keyCode == 8,
              !event.isARepeat else { return }

        if detector.record() {
            onDoubleCmdC?()
        }
    }
}

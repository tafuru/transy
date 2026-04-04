import AppKit

@MainActor
final class ClipboardMonitor {
    private var timer: Timer?
    private var appNapActivity: NSObjectProtocol?
    private var lastChangeCount: Int = 0
    private var lastProcessedText: String?
    private var onNewText: ((String) -> Void)?

    private static let concealedType = NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType")
    private static let transientType = NSPasteboard.PasteboardType("org.nspasteboard.TransientType")

    func start(onNewText: @escaping (String) -> Void) {
        self.onNewText = onNewText
        lastChangeCount = NSPasteboard.general.changeCount
        lastProcessedText = nil

        appNapActivity = ProcessInfo.processInfo.beginActivity(
            options: .userInitiatedAllowingIdleSystemSleep,
            reason: "Clipboard monitoring requires timely timer execution"
        )

        timer = Timer.scheduledTimer(
            withTimeInterval: 0.5,
            repeats: true
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.poll()
            }
        }
        timer?.tolerance = 0.1
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        if let activity = appNapActivity {
            ProcessInfo.processInfo.endActivity(activity)
            appNapActivity = nil
        }
        lastProcessedText = nil
        onNewText = nil
    }

    /// Record a self-originated clipboard write to prevent re-triggering.
    func recordSelfWrite() {
        lastChangeCount = NSPasteboard.general.changeCount
    }

    private func poll() {
        let pb = NSPasteboard.general
        let currentCount = pb.changeCount

        guard currentCount != lastChangeCount else { return }
        lastChangeCount = currentCount

        guard let types = pb.types, types.contains(.string) else { return }

        guard !types.contains(Self.concealedType),
              !types.contains(Self.transientType) else { return }

        guard let text = pb.string(forType: .string) else { return }

        guard text != lastProcessedText else { return }
        lastProcessedText = text

        onNewText?(text)
    }
}

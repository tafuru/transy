import AppKit
import ApplicationServices
import SwiftUI

@MainActor
final class GuidanceWindowController: NSWindowController {
    static let shared = GuidanceWindowController()
    var onPermissionGranted: (() -> Void)?

    private var trustPollTimer: Timer?

    private init() {
        super.init(window: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("not used")
    }

    func showIfNeeded() {
        guard !AXIsProcessTrusted() else { return }

        if window == nil {
            let hosting = NSHostingController(rootView: GuidanceView())
            hosting.view.frame = NSRect(x: 0, y: 0, width: 340, height: 1)
            // Let the hosting controller size the window to fit content
            let win = NSWindow(contentViewController: hosting)
            win.title = "Transy — Accessibility Access"
            win.styleMask = [.titled, .closable]
            win.level = .floating
            win.isReleasedWhenClosed = false // retain for reuse
            self.window = win
        }

        startTrustPolling()
        NSApp.activate()
        window?.makeKeyAndOrderFront(nil)
    }

    private func startTrustPolling() {
        guard trustPollTimer == nil else { return }

        trustPollTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard AXIsProcessTrusted() else { return }
                self?.trustPollTimer?.invalidate()
                self?.trustPollTimer = nil
                self?.window?.orderOut(nil)
                self?.onPermissionGranted?()
            }
        }
    }
}

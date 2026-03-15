import AppKit
import SwiftUI

// NSWindowStyleMaskNonactivatingPanel (1<<7) is not exposed as a named Swift member.
private extension NSWindow.StyleMask {
    static let nonActivatingPanel = NSWindow.StyleMask(rawValue: 1 << 7)
}

/// Hosts the popup NSPanel. Non-activating, floating, fade-in, dismiss on Escape or outside click.
@MainActor
final class PopupController {

    private lazy var panel: NSPanel = makePanel()
    private var dismissMonitors: [Any] = []
    private var onDismiss: (() -> Void)?

    private func makePanel() -> NSPanel {
        let styleMask: NSWindow.StyleMask = [.borderless, .nonActivatingPanel]
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 80),
            styleMask: styleMask,
            backing: .buffered,
            defer: false
        )
        panel.level = NSWindow.Level.floating
        panel.collectionBehavior = NSWindow.CollectionBehavior([.canJoinAllSpaces, .stationary, .ignoresCycle])
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false   // CRITICAL: without this, panel vanishes when source app regains focus
        panel.backgroundColor = NSColor.clear
        panel.isOpaque = false
        panel.hasShadow = true
        return panel
    }

    /// Show the popup with translation-driven content. If already visible, replaces content in-place (no stacking).
    func show(
        translationCoordinator: TranslationCoordinator,
        onDismiss: @escaping () -> Void
    ) {
        // Replace content if popup is already visible (rapid re-trigger: reuse position, replace text)
        removeDismissMonitors()
        self.onDismiss = onDismiss

        // Rapid re-trigger must tear down the old hosted SwiftUI subtree before installing the
        // next one. Reusing the panel is fine; reusing the hosting tree can leave the previous
        // translationTask/session alive long enough to make the new request feel queued behind it.
        panel.contentView = nil

        let view = PopupView(translationCoordinator: translationCoordinator)
        panel.contentView = NSHostingView(rootView: view)
        panel.setFrameOrigin(topCenterOrigin(for: panel))
        panel.alphaValue = 0
        // orderFrontRegardless() is required for background/accessory apps (Transy never activates).
        // orderFront(nil) is a documented no-op when the app is not active.
        // orderFrontRegardless() shows the panel without making it key or activating the app (POP-01).
        panel.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.15   // subtle fade-in (CONTEXT.md: "subtle fade-in, not strong motion")
            panel.animator().alphaValue = 1
        }
        attachDismissMonitors()
    }

    func dismiss() {
        removeDismissMonitors()
        // Dismiss must tear down the hosted SwiftUI tree, not just hide the panel. The
        // translationTask is view-scoped, so leaving the hosting view attached after an
        // outside click / Escape can let the old request keep running until the next show.
        panel.contentView = nil
        panel.orderOut(nil)
        onDismiss?()
        onDismiss = nil
    }

    var hasHostedPopupContent: Bool {
        panel.contentView != nil
    }

    // MARK: - Dismiss monitors (global — panel is not key window, local monitors won't fire)

    private func attachDismissMonitors() {
        let esc = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            MainActor.assumeIsolated {
                if event.keyCode == 53 { self?.dismiss() }   // 53 = Escape
            }
        }
        let click = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] event in
            MainActor.assumeIsolated {
                guard let self else { return }
                if !self.panel.frame.contains(NSEvent.mouseLocation) {
                    self.dismiss()
                }
            }
        }
        dismissMonitors = [esc, click].compactMap { $0 }
    }

    private func removeDismissMonitors() {
        dismissMonitors.forEach { NSEvent.removeMonitor($0) }
        dismissMonitors = []
    }

    // MARK: - Screen placement

    /// Returns the top-center origin for the panel on the screen containing the mouse cursor.
    /// Uses mouse cursor (not NSScreen.main) because Transy is not frontmost at trigger time.
    private func topCenterOrigin(for panel: NSPanel) -> NSPoint {
        let screen = activeScreen()
        let sf = screen.visibleFrame   // excludes menu bar at top (visibleFrame.maxY = just below menu bar)
        let pw = panel.frame.width
        let ph = panel.frame.height
        let x = sf.midX - pw / 2
        let y = sf.maxY - ph - 24    // 24pt inset below the menu bar
        return NSPoint(x: x, y: y)
    }

    private func activeScreen() -> NSScreen {
        let cursor = NSEvent.mouseLocation
        if let screen = NSScreen.screens.first(where: { NSMouseInRect(cursor, $0.frame, false) }) {
            return screen
        }
        if let screen = NSScreen.main ?? NSScreen.screens.first {
            return screen
        }
        fatalError("PopupController requires at least one NSScreen")
    }
}

import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Belt-and-suspenders alongside LSUIElement in Info.plist
        NSApp.setActivationPolicy(.accessory)
        // Phase 2: attach HotkeyMonitor here
        // Phase 2: configure NSPanel here
    }
}

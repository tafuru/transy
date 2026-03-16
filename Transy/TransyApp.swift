import SwiftUI

@main
struct TransyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("Transy", systemImage: "character.bubble") {
            MenuBarView()
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView(settingsStore: appDelegate.settingsStore)
        }
    }
}

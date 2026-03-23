import SwiftUI

struct SettingsView: View {
    let settingsStore: SettingsStore

    var body: some View {
        TabView {
            GeneralSettingsView(settingsStore: settingsStore)
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }

            AboutSettingsView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 420)
    }
}

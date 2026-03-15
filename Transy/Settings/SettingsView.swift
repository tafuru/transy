import SwiftUI

struct SettingsView: View {
    let settingsStore: SettingsStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Transy")
                .font(.headline)
            Text("Settings will be available once translation is set up.")
                .foregroundStyle(.secondary)
            Text("Target: \(settingsStore.targetLanguage.minimalIdentifier)")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(24)
        .frame(width: 320, height: 140)
    }
}

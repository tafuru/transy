import SwiftUI

struct SettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Transy")
                .font(.headline)
            Text("Settings coming soon.")
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(width: 320, height: 120)
    }
}

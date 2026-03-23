import SwiftUI

struct AboutSettingsView: View {
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    var body: some View {
        Form {
            Section {
                VStack(spacing: 12) {
                    Text("Transy")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Version \(appVersion)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("A lightweight macOS menu bar translator")
                        .font(.body)
                        .foregroundStyle(.secondary)

                    if let url = URL(string: "https://github.com/tafuru/transy") {
                        Link("GitHub Repository", destination: url)
                            .font(.body)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .formStyle(.grouped)
    }
}

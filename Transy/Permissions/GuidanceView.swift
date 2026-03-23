import SwiftUI
import AppKit

struct GuidanceView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Accessibility Access Required")
                .font(.headline)
            Text("Transy uses Accessibility access to detect the double ⌘C shortcut that triggers translations. This permission lets the app listen for your keyboard shortcut so it can provide translations.")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Text("Open System Settings → Privacy & Security → Accessibility and enable Transy.")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button("Open System Settings") {
                guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else { return }
                NSWorkspace.shared.open(url)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
        }
        .padding(20)
        .frame(width: 340)
    }
}

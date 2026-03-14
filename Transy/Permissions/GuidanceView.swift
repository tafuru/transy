import SwiftUI
import AppKit

struct GuidanceView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Accessibility Access Required")
                .font(.headline)
            Text("Transy needs Accessibility access to detect the double-Cmd+C trigger.\n\nOpen System Settings → Privacy & Security → Accessibility and enable Transy.")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button("Open System Settings") {
                NSWorkspace.shared.open(
                    URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                )
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
        }
        .padding(20)
        .frame(width: 340)
    }
}

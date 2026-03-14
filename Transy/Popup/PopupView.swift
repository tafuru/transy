import SwiftUI

/// Popup content: source text in muted loading style. No chrome, no label, content-only.
/// In Phase 3, foregroundStyle will change from .secondary to .primary when translation result arrives.
struct PopupView: View {
    let sourceText: String

    var body: some View {
        Text(sourceText)
            .font(.body)
            .foregroundStyle(.secondary)        // muted but readable (NOT .redacted — heavy blobs)
            .lineLimit(4)                       // truncate to 4 lines (CONTEXT.md: "a few lines then truncate")
            .truncationMode(.tail)
            .multilineTextAlignment(.leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(width: 380, alignment: .leading)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}

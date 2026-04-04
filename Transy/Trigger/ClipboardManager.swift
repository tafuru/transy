import AppKit

/// Saves, reads, and restores NSPasteboard.general contents around a trigger capture.
/// All methods run on @MainActor and are used from AppDelegate during the trigger flow.
@MainActor
final class ClipboardManager {
    /// Snapshot the current clipboard contents before the source app writes the selection.
    /// Call this on the first Cmd+C keyDown so the user's original clipboard is preserved.
    func saveCurrentContents() -> [NSPasteboardItem] {
        let pb = NSPasteboard.general
        return (pb.pasteboardItems ?? []).compactMap { item in
            let copy = NSPasteboardItem()
            for type in item.types {
                if let data = item.data(forType: type) {
                    copy.setData(data, forType: type)
                }
            }
            return copy
        }
    }

    /// Read the current top-of-pasteboard string.
    /// Call this after the 80ms delay so the source app has finished writing the selection.
    func readSelectedText() -> String? {
        NSPasteboard.general.string(forType: .string)
    }

    /// Restore previously saved items. Clears the pasteboard first.
    /// Pass an empty array to leave the clipboard empty (e.g., it was empty before trigger).
    func restore(_ savedItems: [NSPasteboardItem]) {
        let pb = NSPasteboard.general
        pb.clearContents()
        if !savedItems.isEmpty {
            pb.writeObjects(savedItems)
        }
    }
}

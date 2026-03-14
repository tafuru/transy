import AppKit

/// Keeps the clipboard snapshot that should be restored when a popup session ends.
/// The first trigger in a visible popup session wins; later re-triggers reuse it.
struct ClipboardRestoreSession {
    private var restoreSnapshot: [NSPasteboardItem]?

    mutating func snapshotForSession(_ preSnapshot: [NSPasteboardItem]) -> [NSPasteboardItem] {
        if let restoreSnapshot {
            return restoreSnapshot
        }

        restoreSnapshot = preSnapshot
        return preSnapshot
    }

    mutating func consumeRestoreSnapshot() -> [NSPasteboardItem]? {
        defer { restoreSnapshot = nil }
        return restoreSnapshot
    }
}

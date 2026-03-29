import AppKit
import Testing
@testable import Transy

struct ClipboardManagerTests {
    @Test("save and restore preserves string content")
    @MainActor
    func saveRestorePreservesString() {
        let mgr = ClipboardManager()
        let originalClipboard = mgr.saveCurrentContents()
        defer { mgr.restore(originalClipboard) }

        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString("original clipboard content", forType: .string)

        let saved = mgr.saveCurrentContents()

        // Overwrite clipboard to simulate source app writing selection
        pb.clearContents()
        pb.setString("selected text", forType: .string)

        // Restore
        mgr.restore(saved)

        #expect(pb.string(forType: .string) == "original clipboard content")
    }

    @Test("readSelectedText returns current pasteboard string")
    @MainActor
    func readSelectedTextReturnsCurrent() {
        let mgr = ClipboardManager()
        let originalClipboard = mgr.saveCurrentContents()
        defer { mgr.restore(originalClipboard) }

        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString("hello world", forType: .string)

        #expect(mgr.readSelectedText() == "hello world")
    }

    @Test("restore with empty items clears clipboard")
    @MainActor
    func restoreEmptyItemsClearsClipboard() {
        let mgr = ClipboardManager()
        let originalClipboard = mgr.saveCurrentContents()
        defer { mgr.restore(originalClipboard) }

        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString("something", forType: .string)

        mgr.restore([]) // restore to empty state

        // After clearing and writing nothing, string should be nil
        #expect(pb.string(forType: .string) == nil)
    }

    /// Regression test for the first-press clipboard snapshot bug:
    /// The snapshot must be taken BEFORE the source app overwrites the clipboard (first Cmd+C),
    /// not after (second Cmd+C). This test verifies that a snapshot captured before the source app
    /// copies the selection correctly restores the original clipboard — not the selected text.
    @Test("snapshot taken before source-app copy restores original clipboard (regression)")
    @MainActor
    func snapshotBeforeSourceAppCopyRestoresOriginal() {
        let mgr = ClipboardManager()
        let originalClipboard = mgr.saveCurrentContents()
        defer { mgr.restore(originalClipboard) }

        let pb = NSPasteboard.general

        // 1. User's pre-existing clipboard ("AAA")
        pb.clearContents()
        pb.setString("AAA", forType: .string)

        // 2. HotkeyMonitor fires on first Cmd+C — snapshot captured here (clipboard still "AAA")
        let firstPressSnapshot = mgr.saveCurrentContents()

        // 3. Source app processes first Cmd+C and writes selection ("BBB") to clipboard
        pb.clearContents()
        pb.setString("BBB", forType: .string)

        // 4. Verify readSelectedText picks up "BBB" for the popup
        #expect(mgr.readSelectedText() == "BBB")

        // 5. Popup is dismissed — restore using the first-press snapshot
        mgr.restore(firstPressSnapshot)

        // 6. Clipboard must be back to "AAA", not "BBB"
        #expect(
            pb.string(forType: .string) == "AAA",
            "restore must use first-press snapshot (AAA), not the selection (BBB)"
        )
    }
}

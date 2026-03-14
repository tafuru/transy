import Testing
import AppKit
@testable import Transy

@Suite("ClipboardManager")
struct ClipboardManagerTests {

    @Test("save and restore preserves string content")
    @MainActor
    func saveRestorePreservesString() {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString("original clipboard content", forType: .string)

        let mgr = ClipboardManager()
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
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString("hello world", forType: .string)

        let mgr = ClipboardManager()
        #expect(mgr.readSelectedText() == "hello world")
    }

    @Test("restore with empty items clears clipboard")
    @MainActor
    func restoreEmptyItemsClearsClipboard() {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString("something", forType: .string)

        let mgr = ClipboardManager()
        mgr.restore([])    // restore to empty state

        // After clearing and writing nothing, string should be nil
        #expect(pb.string(forType: .string) == nil)
    }
}

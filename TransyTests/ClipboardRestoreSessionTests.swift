import AppKit
import Testing
@testable import Transy

struct ClipboardRestoreSessionTests {
    @Test("first trigger stores its snapshot")
    @MainActor
    func firstTriggerStoresSnapshot() {
        var session = ClipboardRestoreSession()

        let snapshot = session.snapshotForSession(makeSnapshot("AAA"))

        #expect(firstString(in: snapshot) == "AAA")
    }

    @Test("retrigger keeps the original snapshot while popup session is active")
    @MainActor
    func retriggerKeepsOriginalSnapshot() {
        var session = ClipboardRestoreSession()

        _ = session.snapshotForSession(makeSnapshot("AAA"))
        let reused = session.snapshotForSession(makeSnapshot("BBB"))
        let restored = session.consumeRestoreSnapshot()

        #expect(firstString(in: reused) == "AAA")
        #expect(firstString(in: restored) == "AAA")
    }

    @Test("consuming the snapshot resets the session")
    @MainActor
    func consumingSnapshotResetsSession() {
        var session = ClipboardRestoreSession()

        _ = session.snapshotForSession(makeSnapshot("AAA"))
        _ = session.consumeRestoreSnapshot()
        let next = session.snapshotForSession(makeSnapshot("CCC"))

        #expect(firstString(in: next) == "CCC")
    }

    @MainActor
    private func makeSnapshot(_ string: String) -> [NSPasteboardItem] {
        let item = NSPasteboardItem()
        item.setString(string, forType: .string)
        return [item]
    }

    @MainActor
    private func firstString(in snapshot: [NSPasteboardItem]?) -> String? {
        snapshot?.first?.string(forType: .string)
    }
}

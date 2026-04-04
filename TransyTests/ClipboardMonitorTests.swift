import AppKit
import Testing
@testable import Transy

@Suite(.serialized)
struct ClipboardMonitorTests {

    private func savePasteboard() -> [NSPasteboardItem] {
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

    private func restorePasteboard(_ items: [NSPasteboardItem]) {
        let pb = NSPasteboard.general
        pb.clearContents()
        if !items.isEmpty { pb.writeObjects(items) }
    }

    @Test("detects new clipboard text")
    @MainActor
    func detectsNewClipboardText() async throws {
        let saved = savePasteboard()
        defer { restorePasteboard(saved) }

        var receivedText: String?
        let monitor = ClipboardMonitor()
        monitor.start { text in receivedText = text }
        defer { monitor.stop() }

        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString("test text", forType: .string)

        try await Task.sleep(for: .milliseconds(600))
        #expect(receivedText == "test text")
    }

    @Test("skips concealed pasteboard type")
    @MainActor
    func skipsConcealedType() async throws {
        let saved = savePasteboard()
        defer { restorePasteboard(saved) }

        var receivedText: String?
        let monitor = ClipboardMonitor()
        monitor.start { text in receivedText = text }
        defer { monitor.stop() }

        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString("secret", forType: .string)
        pb.setData(Data(), forType: NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType"))

        try await Task.sleep(for: .milliseconds(600))
        #expect(receivedText == nil)
    }

    @Test("skips transient pasteboard type")
    @MainActor
    func skipsTransientType() async throws {
        let saved = savePasteboard()
        defer { restorePasteboard(saved) }

        var receivedText: String?
        let monitor = ClipboardMonitor()
        monitor.start { text in receivedText = text }
        defer { monitor.stop() }

        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString("transient", forType: .string)
        pb.setData(Data(), forType: NSPasteboard.PasteboardType("org.nspasteboard.TransientType"))

        try await Task.sleep(for: .milliseconds(600))
        #expect(receivedText == nil)
    }

    @Test("skips duplicate text")
    @MainActor
    func skipsDuplicateText() async throws {
        let saved = savePasteboard()
        defer { restorePasteboard(saved) }

        var callCount = 0
        let monitor = ClipboardMonitor()
        monitor.start { _ in callCount += 1 }
        defer { monitor.stop() }

        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString("hello", forType: .string)

        try await Task.sleep(for: .milliseconds(600))
        #expect(callCount == 1)

        pb.clearContents()
        pb.setString("hello", forType: .string)

        try await Task.sleep(for: .milliseconds(600))
        #expect(callCount == 1)
    }

    @Test("recordSelfWrite prevents re-trigger")
    @MainActor
    func recordSelfWritePreventsTrigger() async throws {
        let saved = savePasteboard()
        defer { restorePasteboard(saved) }

        var receivedText: String?
        let monitor = ClipboardMonitor()
        monitor.start { text in receivedText = text }
        defer { monitor.stop() }

        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString("self-written", forType: .string)
        monitor.recordSelfWrite()

        try await Task.sleep(for: .milliseconds(600))
        #expect(receivedText == nil)
    }

    @Test("does not trigger on pre-existing clipboard at start")
    @MainActor
    func doesNotTriggerOnPreExistingClipboard() async throws {
        let saved = savePasteboard()
        defer { restorePasteboard(saved) }

        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString("existing text", forType: .string)

        var receivedText: String?
        let monitor = ClipboardMonitor()
        monitor.start { text in receivedText = text }
        defer { monitor.stop() }

        try await Task.sleep(for: .milliseconds(600))
        #expect(receivedText == nil)
    }
}

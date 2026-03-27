import Foundation
import Testing
@testable import Transy

struct TranslationRaceGuardTests {
    @Test("stale success completion is ignored after a newer request begins")
    @MainActor
    func staleSuccessIsIgnored() {
        let coordinator = TranslationCoordinator()
        let staleRequestID = coordinator.begin(sourceText: "古い")
        let currentRequestID = coordinator.begin(sourceText: "新しい")

        coordinator.finish(
            requestID: staleRequestID,
            sourceText: "古い",
            translatedText: "Old"
        )

        switch coordinator.popupState {
        case let .loading(requestID, sourceText):
            #expect(requestID == currentRequestID)
            #expect(sourceText == "新しい")
        default:
            Issue.record("Expected stale success write to be ignored")
        }
    }

    @Test("stale error completion is ignored after a newer request begins")
    @MainActor
    func staleErrorIsIgnored() {
        let coordinator = TranslationCoordinator()
        let staleRequestID = coordinator.begin(sourceText: "古い")
        let currentRequestID = coordinator.begin(sourceText: "新しい")

        coordinator.fail(
            requestID: staleRequestID,
            sourceText: "古い",
            message: "Translation failed."
        )

        switch coordinator.popupState {
        case let .loading(requestID, sourceText):
            #expect(requestID == currentRequestID)
            #expect(sourceText == "新しい")
        default:
            Issue.record("Expected stale error write to be ignored")
        }
    }
}

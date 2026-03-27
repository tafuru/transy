import Foundation
import Testing
@testable import Transy

struct TranslationCoordinatorTests {
    @Test("begin starts loading and finish publishes result for active request")
    @MainActor
    func finishMovesLoadingToResult() {
        let coordinator = TranslationCoordinator()

        let requestID = coordinator.begin(sourceText: "こんにちは")

        switch coordinator.popupState {
        case let .loading(loadingRequestID, sourceText):
            #expect(loadingRequestID == requestID)
            #expect(sourceText == "こんにちは")
        default:
            Issue.record("Expected loading state after begin")
        }

        coordinator.finish(
            requestID: requestID,
            sourceText: "こんにちは",
            translatedText: "Hello"
        )

        switch coordinator.popupState {
        case let .result(resultRequestID, sourceText, translatedText):
            #expect(resultRequestID == requestID)
            #expect(sourceText == "こんにちは")
            #expect(translatedText == "Hello")
        default:
            Issue.record("Expected result state after finish")
        }
    }

    @Test("begin starts loading and fail publishes error for active request")
    @MainActor
    func failMovesLoadingToError() {
        let coordinator = TranslationCoordinator()
        let requestID = coordinator.begin(sourceText: "短い")

        coordinator.fail(
            requestID: requestID,
            sourceText: "短い",
            message: "Couldn't detect the source language."
        )

        switch coordinator.popupState {
        case let .error(errorRequestID, sourceText, message):
            #expect(errorRequestID == requestID)
            #expect(sourceText == "短い")
            #expect(message == "Couldn't detect the source language.")
        default:
            Issue.record("Expected error state after fail")
        }
    }

    @Test("dismiss clears visible state and invalidates active request identity")
    @MainActor
    func dismissResetsPopupStateAndActiveRequest() {
        let coordinator = TranslationCoordinator()
        _ = coordinator.begin(sourceText: "こんにちは")

        coordinator.dismiss()

        #expect(coordinator.activeRequestID == nil)

        switch coordinator.popupState {
        case .hidden:
            break
        default:
            Issue.record("Expected popupState to reset to .hidden after dismiss")
        }
    }
}

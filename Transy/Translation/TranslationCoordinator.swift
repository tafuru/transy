import Foundation
import Observation

@MainActor
@Observable
final class TranslationCoordinator {
    enum PopupState: Equatable {
        case hidden
        case loading(requestID: UUID, sourceText: String)
        case result(requestID: UUID, sourceText: String, translatedText: String)
        case error(requestID: UUID, sourceText: String, message: String)
    }

    private(set) var activeRequestID: UUID?
    private(set) var popupState: PopupState = .hidden

    func begin(sourceText: String) -> UUID {
        let requestID = UUID()
        activeRequestID = requestID
        popupState = .loading(requestID: requestID, sourceText: sourceText)
        return requestID
    }

    func finish(requestID: UUID, sourceText: String, translatedText: String) {
        guard activeRequestID == requestID else { return }
        popupState = .result(
            requestID: requestID,
            sourceText: sourceText,
            translatedText: translatedText
        )
    }

    func fail(requestID: UUID, sourceText: String, message: String) {
        guard activeRequestID == requestID else { return }
        popupState = .error(
            requestID: requestID,
            sourceText: sourceText,
            message: message
        )
    }

    func dismiss() {
        activeRequestID = nil
        popupState = .hidden
    }
}

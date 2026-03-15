import SwiftUI
import Translation

/// Popup content stays compact and quiet while swapping between loading, result, and error states.
struct PopupView: View {
    let translationCoordinator: TranslationCoordinator
    let availabilityClient: TranslationAvailabilityClient

    init(
        translationCoordinator: TranslationCoordinator,
        availabilityClient: TranslationAvailabilityClient = TranslationAvailabilityClient()
    ) {
        self.translationCoordinator = translationCoordinator
        self.availabilityClient = availabilityClient
    }

    var body: some View {
        switch translationCoordinator.popupState {
        case let .loading(requestID, sourceText):
            LoadingPopupText(
                requestContext: .init(requestID: requestID, sourceText: sourceText),
                availabilityClient: availabilityClient,
                onResult: finishIfStillActive,
                onError: failIfStillActive
            )
        case let .result(_, _, translatedText):
            PopupText(text: translatedText, isMuted: false)
        case let .error(_, _, message):
            PopupText(text: message, isMuted: false)
        case .hidden:
            PopupText(text: "", isMuted: true)
        }
    }

    private func finishIfStillActive(
        requestID: UUID,
        sourceText: String,
        translatedText: String
    ) async {
        await MainActor.run {
            guard translationCoordinator.activeRequestID == requestID else { return }
            translationCoordinator.finish(
                requestID: requestID,
                sourceText: sourceText,
                translatedText: translatedText
            )
        }
    }

    private func failIfStillActive(
        requestID: UUID,
        sourceText: String,
        message: String
    ) async {
        await MainActor.run {
            guard translationCoordinator.activeRequestID == requestID else { return }
            translationCoordinator.fail(
                requestID: requestID,
                sourceText: sourceText,
                message: message
            )
        }
    }
}

private struct PopupText: View {
    let text: String
    let isMuted: Bool

    var body: some View {
        Text(text)
            .font(.body)
            .foregroundStyle(isMuted ? .secondary : .primary)
            .lineLimit(4)
            .truncationMode(.tail)
            .multilineTextAlignment(.leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(width: 380, alignment: .leading)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}

private struct LoadingPopupText: View {
    let requestContext: LoadingRequestContext
    let availabilityClient: TranslationAvailabilityClient
    let onResult: @Sendable (UUID, String, String) async -> Void
    let onError: @Sendable (UUID, String, String) async -> Void

    var body: some View {
        let requestContext = requestContext
        let availabilityClient = availabilityClient
        let onResult = onResult
        let onError = onError

        return PopupText(text: requestContext.sourceText, isMuted: true)
            .translationTask(source: nil, target: availabilityClient.targetLanguage) { session in
                nonisolated(unsafe) let session = session

                do {
                    let preflightResult = try await availabilityClient.preflight(for: requestContext.sourceText)

                    switch preflightResult {
                    case .ready:
                        break
                    case let .unavailable(message):
                        await onError(requestContext.requestID, requestContext.sourceText, message)
                        return
                    }

                    let response = try await session.translate(requestContext.sourceText)
                    await onResult(
                        requestContext.requestID,
                        requestContext.sourceText,
                        response.targetText
                    )
                } catch is CancellationError {
                    return
                } catch {
                    await onError(
                        requestContext.requestID,
                        requestContext.sourceText,
                        TranslationErrorMapper.message(for: error)
                    )
                }
            }
    }
}

private struct LoadingRequestContext: Sendable {
    let requestID: UUID
    let sourceText: String
}

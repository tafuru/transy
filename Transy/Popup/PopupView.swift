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
            .id(requestID)
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
    @State private var translationConfiguration: TranslationSession.Configuration?

    var body: some View {
        let requestContext = requestContext
        let availabilityClient = availabilityClient
        let onResult = onResult
        let onError = onError

        return PopupText(text: requestContext.sourceText, isMuted: true)
            .onChange(of: requestContext.requestID, initial: true) { _, _ in
                translationConfiguration = nextTranslationConfiguration(
                    after: translationConfiguration,
                    targetLanguage: availabilityClient.targetLanguage
                )
            }
            .translationTask(translationConfiguration) { session in
                nonisolated(unsafe) let session = session
                let cancelHandle = TranslationSessionCancelHandle(session: session)

                do {
                    try await performTranslation(
                        requestContext: requestContext,
                        availabilityClient: availabilityClient,
                        session: session,
                        cancelHandle: cancelHandle,
                        onResult: onResult,
                        onError: onError
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

private func performTranslation(
    requestContext: LoadingRequestContext,
    availabilityClient: TranslationAvailabilityClient,
    session: TranslationSession,
    cancelHandle: TranslationSessionCancelHandle,
    onResult: @escaping @Sendable (UUID, String, String) async -> Void,
    onError: @escaping @Sendable (UUID, String, String) async -> Void
) async throws {
    try await withTaskCancellationHandler(
        operation: {
            let preflightResult = try await availabilityClient.preflight(
                for: requestContext.sourceText
            )

            switch preflightResult {
            case .ready:
                break
            case let .unavailable(message):
                await onError(requestContext.requestID, requestContext.sourceText, message)
                return
            }

            try Task.checkCancellation()

            let response = try await session.translate(requestContext.sourceText)
            await onResult(
                requestContext.requestID,
                requestContext.sourceText,
                response.targetText
            )
        },
        onCancel: {
            cancelHandle.cancelIfAvailable()
        }
    )
}

private struct TranslationSessionCancelHandle: @unchecked Sendable {
    let session: TranslationSession

    func cancelIfAvailable() {
        // Tahoe adds TranslationSession.cancel(). Keep the handle scoped to the
        // active translationTask cancellation path so we never retain the session
        // beyond the view-owned lifecycle Apple documents.
        cancelTranslationSessionIfAvailable(session)
    }
}

private func cancelTranslationSessionIfAvailable(_ session: TranslationSession) {
    guard #available(macOS 26.0, *) else { return }
    cancelTranslationSession(session)
}

@available(macOS 26.0, *)
private func cancelTranslationSession(_ session: TranslationSession) {
    session.cancel()
}

func nextTranslationConfiguration(
    after existingConfiguration: TranslationSession.Configuration?,
    targetLanguage: Locale.Language
) -> TranslationSession.Configuration {
    var configuration = existingConfiguration
        ?? TranslationSession.Configuration(source: nil, target: targetLanguage)

    configuration.source = nil
    configuration.target = targetLanguage

    if existingConfiguration != nil {
        configuration.invalidate()
    }

    return configuration
}

import SwiftUI
import Translation

/// Popup content stays compact and quiet while swapping between loading, result, and error states.
struct PopupView: View {
    let translationCoordinator: TranslationCoordinator
    let availabilityClient: TranslationAvailabilityClient
    let settingsStore: SettingsStore

    init(
        translationCoordinator: TranslationCoordinator,
        availabilityClient: TranslationAvailabilityClient,
        settingsStore: SettingsStore
    ) {
        self.translationCoordinator = translationCoordinator
        self.availabilityClient = availabilityClient
        self.settingsStore = settingsStore
    }

    var body: some View {
        switch translationCoordinator.popupState {
        case let .loading(requestID, sourceText):
            LoadingPopupText(
                requestContext: .init(requestID: requestID, sourceText: sourceText),
                availabilityClient: availabilityClient,
                settingsStore: settingsStore,
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

struct PopupText: View {
    let text: String
    let isMuted: Bool

    private static let maxPopupWidth: CGFloat = 640
    private static let maxPopupHeight: CGFloat = 200

    @State private var contentHeight: CGFloat = 0

    var body: some View {
        ScrollView(.vertical) {
            Text(text)
                .font(.system(size: 15))
                .foregroundStyle(isMuted ? .secondary : .primary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: ContentHeightPreferenceKey.self,
                            value: geo.size.height
                        )
                    }
                )
        }
        .scrollBounceBehavior(.basedOnSize)
        .frame(maxWidth: Self.maxPopupWidth)
        .frame(height: min(max(contentHeight, 1), Self.maxPopupHeight))
        .fixedSize(horizontal: true, vertical: false)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .onPreferenceChange(ContentHeightPreferenceKey.self) { height in
            contentHeight = height
        }
    }
}

private struct ContentHeightPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct LoadingPopupText: View {
    let requestContext: LoadingRequestContext
    let availabilityClient: TranslationAvailabilityClient
    let settingsStore: SettingsStore
    let onResult: @Sendable (UUID, String, String) async -> Void
    let onError: @Sendable (UUID, String, String) async -> Void
    @State private var translationConfiguration: TranslationSession.Configuration?

    var body: some View {
        let requestContext = requestContext
        let availabilityClient = availabilityClient
        let settingsStore = settingsStore
        let onResult = onResult
        let onError = onError

        return PopupText(text: requestContext.sourceText, isMuted: true)
            .onChange(of: requestContext.requestID, initial: true) { _, _ in
                translationConfiguration = nextTranslationConfiguration(
                    after: translationConfiguration,
                    targetLanguage: availabilityClient.targetLanguage
                )
            }
            .translationTask(
                translationConfiguration,
                action: Self.translationAction(
                    requestContext: requestContext,
                    availabilityClient: availabilityClient,
                    settingsStore: settingsStore,
                    onResult: onResult,
                    onError: onError
                )
            )
    }

    private nonisolated static func translationAction(
        requestContext: LoadingRequestContext,
        availabilityClient: TranslationAvailabilityClient,
        settingsStore: SettingsStore,
        onResult: @escaping @Sendable (UUID, String, String) async -> Void,
        onError: @escaping @Sendable (UUID, String, String) async -> Void
    ) -> (TranslationSession) async -> Void {
        { session in
            do {
                let preflightResult = try await availabilityClient.preflight(
                    for: requestContext.sourceText
                )

                switch preflightResult {
                case .ready:
                    break
                case .missingModel:
                    // Record missing-model relevance in settings without mutating the active popup
                    await MainActor.run {
                        settingsStore.recordMissingModel(
                            targetLanguage: availabilityClient.targetLanguage,
                            knownSourceLanguage: nil
                        )
                    }
                    await onError(
                        requestContext.requestID,
                        requestContext.sourceText,
                        TranslationErrorMapper.modelNotInstalled
                    )
                    return
                case .unsupported:
                    await onError(
                        requestContext.requestID,
                        requestContext.sourceText,
                        TranslationErrorMapper.unsupportedLanguagePair
                    )
                    return
                case .couldNotDetect:
                    await onError(
                        requestContext.requestID,
                        requestContext.sourceText,
                        TranslationErrorMapper.couldNotDetectSourceLanguage
                    )
                    return
                case let .failed(message):
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

// internal (not private) so TranslationTaskConfigurationReloaderTests can verify behavior
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

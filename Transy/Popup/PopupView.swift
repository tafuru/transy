import SwiftUI
import Translation

/// Popup content stays compact and quiet while swapping between loading, result, and error states.
struct PopupView: View {
    let translationCoordinator: TranslationCoordinator
    let targetLanguage: Locale.Language

    var body: some View {
        switch translationCoordinator.popupState {
        case let .loading(requestID, sourceText):
            LoadingPopupText(
                requestContext: .init(requestID: requestID, sourceText: sourceText),
                targetLanguage: targetLanguage,
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
    let targetLanguage: Locale.Language
    let onResult: @Sendable (UUID, String, String) async -> Void
    let onError: @Sendable (UUID, String, String) async -> Void
    @State private var translationConfiguration: TranslationSession.Configuration?
    @State private var pivotConfiguration: TranslationSession.Configuration?
    @State private var pivotNeeded = false
    @State private var pivotIntermediateText: String?

    var body: some View {
        let requestContext = requestContext
        let targetLanguage = targetLanguage
        let onResult = onResult
        let onError = onError
        let segments = TextChunker.chunk(text: requestContext.sourceText)
        let isPivoting = pivotNeeded
        let intermediateText = pivotIntermediateText
        let callbacks = PivotCallbacks(
            onPivotLeg1Complete: { [self] translatedText in
                await MainActor.run {
                    pivotIntermediateText = translatedText
                    pivotConfiguration = TranslationSession.Configuration(
                        source: Locale.Language(identifier: "en"),
                        target: targetLanguage
                    )
                }
            },
            onStartPivot: { [self] in
                await MainActor.run {
                    pivotNeeded = true
                    var config = translationConfiguration
                        ?? TranslationSession.Configuration(
                            source: nil,
                            target: Locale.Language(identifier: "en")
                        )
                    config.target = Locale.Language(identifier: "en")
                    config.invalidate()
                    translationConfiguration = config
                }
            },
            onResult: onResult,
            onError: onError
        )

        return PopupText(text: requestContext.sourceText, isMuted: true)
            .shimmer()
            .onChange(of: requestContext.requestID, initial: true) { _, _ in
                pivotNeeded = false
                pivotIntermediateText = nil
                pivotConfiguration = nil
                translationConfiguration = nextTranslationConfiguration(
                    after: translationConfiguration,
                    targetLanguage: targetLanguage
                )
            }
            .translationTask(
                translationConfiguration,
                action: Self.primaryAction(
                    requestContext: requestContext,
                    targetLanguage: targetLanguage,
                    segments: segments,
                    isPivoting: isPivoting,
                    callbacks: callbacks
                )
            )
            .translationTask(
                pivotConfiguration,
                action: Self.pivotAction(
                    requestContext: requestContext,
                    intermediateText: intermediateText,
                    callbacks: callbacks
                )
            )
    }

    nonisolated private static func primaryAction(
        requestContext: LoadingRequestContext,
        targetLanguage: Locale.Language,
        segments: [TextChunker.ChunkedSegment],
        isPivoting: Bool,
        callbacks: PivotCallbacks
    ) -> @Sendable (TranslationSession) async -> Void {
        { session in
            do {
                let translatedText = try await translateSegments(
                    session: session,
                    segments: segments,
                    fallbackText: requestContext.sourceText
                )

                if isPivoting {
                    await callbacks.onPivotLeg1Complete(translatedText)
                } else {
                    await callbacks.onResult(
                        requestContext.requestID,
                        requestContext.sourceText,
                        translatedText
                    )
                }
            } catch is CancellationError {
                return
            } catch where TranslationError.unableToIdentifyLanguage ~= error && segments.count > 1 {
                // D-08: Retry with individual chunks for language detection
                await retryChunksForDetection(
                    session: session,
                    segments: segments,
                    requestContext: requestContext,
                    isPivoting: isPivoting,
                    callbacks: callbacks
                )
            } catch where TranslationErrorMapper.isPivotTrigger(error) {
                // Re-pivot guard: if already in pivot mode, source→EN also failed
                guard !isPivoting else {
                    await callbacks.onError(
                        requestContext.requestID,
                        requestContext.sourceText,
                        TranslationErrorMapper.unsupportedLanguagePair
                    )
                    return
                }
                await callbacks.onStartPivot()
            } catch {
                await callbacks.onError(
                    requestContext.requestID,
                    requestContext.sourceText,
                    TranslationErrorMapper.message(for: error)
                )
            }
        }
    }

    nonisolated private static func pivotAction(
        requestContext: LoadingRequestContext,
        intermediateText: String?,
        callbacks: PivotCallbacks
    ) -> @Sendable (TranslationSession) async -> Void {
        { session in
            guard let intermediateText else { return }
            do {
                let pivotSegments = await MainActor.run {
                    TextChunker.chunk(text: intermediateText)
                }
                let translatedText = try await translateSegments(
                    session: session,
                    segments: pivotSegments,
                    fallbackText: intermediateText
                )

                await callbacks.onResult(
                    requestContext.requestID,
                    requestContext.sourceText,
                    translatedText
                )
            } catch is CancellationError {
                return
            } catch {
                // Pivot leg 2 failed — show unsupported pair message (D-10)
                await callbacks.onError(
                    requestContext.requestID,
                    requestContext.sourceText,
                    TranslationErrorMapper.unsupportedLanguagePair
                )
            }
        }
    }

    nonisolated private static func translateSegments(
        session: TranslationSession,
        segments: [TextChunker.ChunkedSegment],
        fallbackText: String
    ) async throws -> String {
        if segments.count <= 1 {
            let response = try await session.translate(
                segments.first?.chunk ?? fallbackText
            )
            return response.targetText
        } else {
            let requests = segments.map { segment in
                TranslationSession.Request(sourceText: segment.chunk)
            }
            let responses = try await session.translations(from: requests)
            return zip(responses, segments)
                .map { response, segment in
                    response.targetText + segment.separator
                }
                .joined()
        }
    }

    nonisolated private static func retryChunksForDetection(
        session: TranslationSession,
        segments: [TextChunker.ChunkedSegment],
        requestContext: LoadingRequestContext,
        isPivoting: Bool,
        callbacks: PivotCallbacks
    ) async {
        let startIndex = min(1, segments.count)
        let endIndex = min(startIndex + 3, segments.count)
        for i in startIndex ..< endIndex {
            do {
                _ = try await session.translate(segments[i].chunk)
                // Detection succeeded — retry full batch
                let translatedText = try await translateSegments(
                    session: session,
                    segments: segments,
                    fallbackText: requestContext.sourceText
                )

                if isPivoting {
                    await callbacks.onPivotLeg1Complete(translatedText)
                } else {
                    await callbacks.onResult(
                        requestContext.requestID,
                        requestContext.sourceText,
                        translatedText
                    )
                }
                return
            } catch where TranslationError.unableToIdentifyLanguage ~= error {
                continue
            } catch where TranslationErrorMapper.isPivotTrigger(error) {
                guard !isPivoting else {
                    await callbacks.onError(
                        requestContext.requestID,
                        requestContext.sourceText,
                        TranslationErrorMapper.unsupportedLanguagePair
                    )
                    return
                }
                await callbacks.onStartPivot()
                return
            } catch {
                await callbacks.onError(
                    requestContext.requestID,
                    requestContext.sourceText,
                    TranslationErrorMapper.message(for: error)
                )
                return
            }
        }
        await callbacks.onError(
            requestContext.requestID,
            requestContext.sourceText,
            TranslationErrorMapper.couldNotDetectSourceLanguage
        )
    }
}

private struct LoadingRequestContext {
    let requestID: UUID
    let sourceText: String
}

private struct PivotCallbacks {
    let onPivotLeg1Complete: @Sendable (String) async -> Void
    let onStartPivot: @Sendable () async -> Void
    let onResult: @Sendable (UUID, String, String) async -> Void
    let onError: @Sendable (UUID, String, String) async -> Void
}

/// internal (not private) so TranslationTaskConfigurationReloaderTests can verify behavior
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

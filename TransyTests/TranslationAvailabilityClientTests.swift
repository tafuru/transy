import Foundation
import Testing
import Translation
@testable import Transy

struct TranslationAvailabilityClientTests {
    @Test("normalizedSourceText trims only surrounding whitespace and newlines")
    func normalizedSourceTextTrimsEdgesOnly() {
        let source = "\n  こんにちは   world  \n"

        #expect(normalizedSourceText(source) == "こんにちは   world")
    }

    @Test("detectionSample collapses repeated whitespace for preflight only")
    func detectionSampleCollapsesWhitespace() {
        let source = "\n  こ ん に ち は \n\n world \t\t test  "

        #expect(detectionSample(from: source) == "こ ん に ち は world test")
    }

    @Test("installed availability maps to ready")
    func installedMapsToReady() async throws {
        let client = TranslationAvailabilityClient { sampleText, targetLanguage in
            #expect(sampleText == "こんにちは 世界")
            #expect(targetLanguage == Locale.Language(identifier: "en"))
            return .installed
        }

        let result = try await client.preflight(for: "\n  こんにちは   世界  \n")

        guard case .ready = result else {
            Issue.record("Expected installed status to map to .ready, got \(String(describing: result))")
            return
        }
    }

    @Test("supported-but-missing availability maps to missingModel")
    func supportedMapsToMissingModel() async throws {
        let client = TranslationAvailabilityClient { _, _ in
            .supported
        }

        let result = try await client.preflight(for: "こんにちは")

        guard case .missingModel = result else {
            Issue.record("Expected .missingModel result, got \(String(describing: result))")
            return
        }
    }

    @Test("unsupported availability maps to unsupported")
    func unsupportedMapsToUnsupported() async throws {
        let client = TranslationAvailabilityClient { _, _ in
            .unsupported
        }

        let result = try await client.preflight(for: "こんにちは")

        guard case .unsupported = result else {
            Issue.record("Expected .unsupported result, got \(String(describing: result))")
            return
        }
    }

    @Test("ambiguous source detection maps to failed with couldn't-detect message")
    func ambiguousSourceMapsToFailed() async throws {
        let client = TranslationAvailabilityClient { _, _ in
            throw FakeAvailabilityError.languageDetectionFailed
        }

        let result = try await client.preflight(for: "??")

        guard case let .failed(message) = result else {
            Issue.record("Expected .failed result, got \(String(describing: result))")
            return
        }

        #expect(message == "Couldn't detect the source language.")
    }

    @Test("preflight cancellation propagates for silent popup teardown")
    func cancellationPropagates() async {
        let client = TranslationAvailabilityClient { _, _ in
            throw CancellationError()
        }

        await #expect(throws: CancellationError.self) {
            _ = try await client.preflight(for: "こんにちは")
        }
    }
}

private enum FakeAvailabilityError: Error {
    case languageDetectionFailed
}

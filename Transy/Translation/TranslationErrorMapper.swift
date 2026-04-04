import Foundation
import Translation

enum TranslationErrorMapper {
    static let unsupportedLanguagePair = "This language pair isn’t supported."
    static let couldNotDetectSourceLanguage = "Couldn't detect the source language."
    static let translationFailed = "Translation failed."

    static func message(for error: any Error) -> String {
        if TranslationError.unableToIdentifyLanguage ~= error || isDetectionFailure(error) {
            return couldNotDetectSourceLanguage
        }

        if TranslationError.unsupportedLanguagePairing ~= error
            || TranslationError.unsupportedSourceLanguage ~= error
            || TranslationError.unsupportedTargetLanguage ~= error {
            return unsupportedLanguagePair
        }

        return translationFailed
    }

    private static func isDetectionFailure(_ error: any Error) -> Bool {
        let reflected = String(reflecting: error).lowercased()
        let described = String(describing: error).lowercased()

        return reflected.contains("unabletoidentifylanguage")
            || reflected.contains("languagedetection")
            || reflected.contains("detect")
            || described.contains("unabletoidentifylanguage")
            || described.contains("languagedetection")
            || described.contains("detect")
    }
}

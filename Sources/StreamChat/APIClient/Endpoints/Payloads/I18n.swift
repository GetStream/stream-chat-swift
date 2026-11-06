//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The automatic translations of a text field, as the API returns them in `i18n` objects.
///
/// An `i18n` object has one `<language-code>_text` key per language, plus `language` for the original language.
/// Messages return it as `i18n`, polls as `name_i18n`, `description_i18n`, `text_i18n` and `answer_text_i18n`.
enum I18n {
    private static let translatedSuffix = "_text"
    private static let originalLanguageKey = "language"

    /// The translations in the `i18n` object, or `nil` when it has none.
    static func translations(from i18n: [String: String]?) -> [TranslationLanguage: String]? {
        guard let i18n, !i18n.isEmpty else { return nil }
        var translated = [TranslationLanguage: String]()
        for (key, value) in i18n where key.hasSuffix(translatedSuffix) {
            translated[TranslationLanguage(languageCode: String(key.dropLast(translatedSuffix.count)))] = value
        }
        return translated.isEmpty ? nil : translated
    }

    /// The original language of the text in the `i18n` object.
    static func originalLanguage(from i18n: [String: String]?) -> String? {
        i18n?[originalLanguageKey]
    }
}

extension I18n {
    /// The translation of the text in the given language, or `nil` when there is none, it is empty, or it is the same as the text.
    static func validTranslation(
        of text: String,
        in translations: [TranslationLanguage: String]?,
        for language: TranslationLanguage,
        originalLanguage: TranslationLanguage?
    ) -> String? {
        guard !text.isEmpty else { return nil }
        guard language != originalLanguage else { return nil }
        guard let translatedText = translations?[language], !translatedText.isEmpty else { return nil }
        guard translatedText != text else { return nil }
        return translatedText
    }
}

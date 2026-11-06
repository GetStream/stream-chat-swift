//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat

extension Poll {
    /// The poll name translated to the given language, or the original name when it has no translation.
    func name(in language: TranslationLanguage?) -> String {
        language.flatMap(translatedName(for:)) ?? name
    }
}

extension PollOption {
    /// The option text translated to the given language, or the original text when it has no translation.
    func text(in language: TranslationLanguage?) -> String {
        language.flatMap(translatedText(for:)) ?? text
    }
}

extension PollVote {
    /// The answer text translated to the given language, or the original text when it has no translation.
    func answerText(in language: TranslationLanguage?) -> String? {
        language.flatMap(translatedAnswerText(for:)) ?? answerText
    }
}

extension PollController {
    /// The language to translate the poll to: the current user's language, when auto translation is enabled.
    func translationLanguage(components: Components) -> TranslationLanguage? {
        guard components.messageAutoTranslationEnabled else { return nil }
        return client.currentUserController().currentUser?.language
    }
}

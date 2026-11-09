//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A structure representing a vote in a poll.
public struct PollVote: Hashable, Equatable, Identifiable, Sendable {
    /// The unique identifier of the poll vote.
    public let id: String
    
    /// The date and time when the poll vote was created.
    public let createdAt: Date
    
    /// The date and time when the poll vote was last updated.
    public let updatedAt: Date
    
    /// The unique identifier of the poll associated with the vote.
    public let pollId: String
    
    /// The unique identifier of the option selected in the poll.
    /// This property is optional and may be `nil` if no option was selected.
    public let optionId: String?
    
    /// A boolean indicating whether the vote is an answer.
    public let isAnswer: Bool
    
    /// The text of the answer provided in the vote.
    /// This property is optional and may be `nil` if no answer text was provided.
    public let answerText: String?
    
    /// The user who submitted the vote.
    /// This property is optional and may be `nil` if the vote was submitted anonymously.
    public let user: ChatUser?

    /// The available automatic translations of the answer text.
    public let answerTextTranslations: [TranslationLanguage: String]?

    /// The original language of the answer text.
    public let originalLanguage: TranslationLanguage?

    init(
        id: String,
        createdAt: Date,
        updatedAt: Date,
        pollId: String,
        optionId: String?,
        isAnswer: Bool,
        answerText: String?,
        user: ChatUser?,
        answerTextTranslations: [TranslationLanguage: String]? = nil,
        originalLanguage: TranslationLanguage? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.pollId = pollId
        self.optionId = optionId
        self.isAnswer = isAnswer
        self.answerText = answerText
        self.user = user
        self.answerTextTranslations = answerTextTranslations
        self.originalLanguage = originalLanguage
    }

    /// Gets the translated answer text given the desired language in case the translation is valid.
    public func translatedAnswerText(for language: TranslationLanguage) -> String? {
        guard let answerText else { return nil }
        return I18n.validTranslation(
            of: answerText,
            in: answerTextTranslations,
            for: language,
            originalLanguage: originalLanguage
        )
    }

    /// The answer text in the given language, or the original text when there is no valid translation to it.
    ///
    /// - Parameter language: The language to show the answer in. If `nil`, the original answer text is returned.
    public func answerText(in language: TranslationLanguage?) -> String? {
        language.flatMap(translatedAnswerText(for:)) ?? answerText
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

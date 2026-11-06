//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The model for an option in a poll.
public struct PollOption: Hashable, Equatable, Identifiable, Sendable {
    /// The unique identifier of the poll option.
    public let id: String
    
    /// The text describing the poll option.
    public var text: String
    
    /// A list of the latest votes received for this poll option.
    public var latestVotes: [PollVote]
    
    /// A dictionary containing custom fields associated with the poll option.
    /// This property is optional and may be `nil`.
    public var extraData: [String: RawJSON]?

    /// The available automatic translations of the poll option text.
    public var translations: [TranslationLanguage: String]?

    /// The original language of the poll option text.
    public var originalLanguage: TranslationLanguage?

    /// Initializes a new instance of `PollOption`.
    ///
    /// - Parameters:
    ///   - id: The unique identifier of the poll option. Defaults to a new UUID string.
    ///   - text: The text describing the poll option.
    ///   - latestVotes: A list of the latest votes received for this poll option. Defaults to an empty array.
    ///   - extraData: A dictionary containing custom fields associated with the poll option. Defaults to `nil`.
    ///   - translations: The available automatic translations of the poll option text. Defaults to `nil`.
    ///   - originalLanguage: The original language of the poll option text. Defaults to `nil`.
    public init(
        id: String = UUID().uuidString,
        text: String,
        latestVotes: [PollVote] = [],
        extraData: [String: RawJSON]? = nil,
        translations: [TranslationLanguage: String]? = nil,
        originalLanguage: TranslationLanguage? = nil
    ) {
        self.id = id
        self.text = text
        self.latestVotes = latestVotes
        self.extraData = extraData
        self.translations = translations
        self.originalLanguage = originalLanguage
    }

    /// Gets the translated text of the poll option given the desired language in case the translation is valid.
    public func translatedText(for language: TranslationLanguage) -> String? {
        I18n.validTranslation(
            of: text,
            in: translations,
            for: language,
            originalLanguage: originalLanguage
        )
    }

    /// The option text in the given language, or the original text when there is no valid translation to it.
    ///
    /// - Parameter language: The language to show the text in. If `nil`, the original text is returned.
    public func text(in language: TranslationLanguage?) -> String {
        language.flatMap(translatedText(for:)) ?? text
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

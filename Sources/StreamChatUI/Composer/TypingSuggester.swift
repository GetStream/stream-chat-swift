//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import UIKit

/// The options to configure the `TypingSuggester`.
public struct TypingSuggestionOptions {
    /// The symbol that typing suggester will use to recognise a suggestion.
    public var symbol: String
    /// Wether the suggester should only be recognising at the start of the input.
    public var shouldTriggerOnlyAtStart: Bool
    /// The minimum required characters for the suggester to start recognising a suggestion.
    public var minimumRequiredCharacters: Int

    /// The options to configure the `TypingSuggester`.
    /// - Parameters:
    ///   - symbol: A String describing the symbol that typing suggester will use to recognise a suggestion.
    ///   - shouldTriggerOnlyAtStart: A Boolean value to determine if suggester should only be recognising at
    ///   the start of the input. By default it is `false`.
    ///   - minimumRequiredCharacters: The minimum required characters for the suggester to start
    ///   recognising a suggestion. By default it is `0`, so the suggester will recognise once the symbol is typed.
    public init(
        symbol: String,
        shouldTriggerOnlyAtStart: Bool = false,
        minimumRequiredCharacters: Int = 0
    ) {
        self.symbol = symbol
        self.shouldTriggerOnlyAtStart = shouldTriggerOnlyAtStart
        self.minimumRequiredCharacters = minimumRequiredCharacters
    }
}

/// A structure that contains the information of the typing suggestion.
public struct TypingSuggestion {
    /// A String representing the currently typing text.
    public let text: String
    /// A NSRange that stores the location of the typing suggestion in relation with the whole input.
    public let locationRange: NSRange

    /// The typing suggestion info.
    /// - Parameters:
    ///   - text: A String representing the currently typing text.
    ///   - locationRange: A NSRange that stores the location of the typing suggestion
    ///   in relation with the whole input.
    public init(text: String, locationRange: NSRange) {
        self.text = text
        self.locationRange = locationRange
    }
}

/// A component responsible for finding typing suggestions in a `UITextView`.
public struct TypingSuggester {
    /// The structure that contains the suggestion configuration.
    public let options: TypingSuggestionOptions

    public init(options: TypingSuggestionOptions) {
        self.options = options
    }

    /// Checks if the user typed the recognising symbol and returns the typing suggestion.
    /// - Parameter textView: The `UITextView` the user is currently typing.
    /// - Returns: The typing suggestion if it was recognised, `nil` otherwise.
    public func typingSuggestion(in textView: UITextView) -> TypingSuggestion? {
        let text = textView.text as NSString
        let caretLocation = textView.selectedRange.location

        // Find the first symbol location before the input caret
        let firstSymbolBeforeCaret = text.rangeOfCharacter(
            from: CharacterSet(charactersIn: options.symbol),
            options: .backwards,
            range: NSRange(location: 0, length: caretLocation)
        )
        // If the symbol does not exist, no typing suggestion found
        guard firstSymbolBeforeCaret.location != NSNotFound else {
            return nil
        }

        // Only show typing suggestions after a space, or at the start of the input
        // valid examples: "@user", "Hello @user"
        // invalid examples: "Hello@user"
        let charIndexBeforeSymbol = firstSymbolBeforeCaret.lowerBound - 1
        let charRangeBeforeSymbol = NSRange(location: charIndexBeforeSymbol, length: 1)
        let textBeforeSymbol = charIndexBeforeSymbol >= 0 ? text.substring(with: charRangeBeforeSymbol) : ""
        guard textBeforeSymbol.isEmpty || textBeforeSymbol == " " else {
            return nil
        }

        // If suggestion is only at the start of the input,
        // should not have text before symbol
        if options.shouldTriggerOnlyAtStart && !textBeforeSymbol.isEmpty {
            return nil
        }

        // The suggestion range. Protect against invalid ranges.
        let suggestionStart = firstSymbolBeforeCaret.upperBound
        let suggestionEnd = caretLocation
        guard suggestionEnd >= suggestionStart else {
            return nil
        }

        // Fetch the suggestion text. The suggestions can't have spaces.
        // valid example: "@luke_skywa..."
        // invalid example: "@luke skywa..."
        let suggestionLocation = NSRange(location: suggestionStart, length: suggestionEnd - suggestionStart)
        let suggestionText = text.substring(with: suggestionLocation)
        guard !suggestionText.contains(" ") else {
            return nil
        }

        // A minimum number of characters can be provided to only show
        // suggestions after the customer has input enough characters.
        guard suggestionText.count >= options.minimumRequiredCharacters else {
            return nil
        }

        return TypingSuggestion(text: suggestionText, locationRange: suggestionLocation)
    }
}

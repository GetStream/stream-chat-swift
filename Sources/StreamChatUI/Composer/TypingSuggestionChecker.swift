//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import UIKit

/// <#Description#>
public struct TypingSuggestionOptions {
    public var symbol: String
    public var shouldTriggerOnlyAtStart: Bool
    public var minimumRequiredCharacters: Int

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

public struct TypingSuggestion {
    public let text: String
    public let location: NSRange

    public init(text: String, location: NSRange) {
        self.text = text
        self.location = location
    }
}

public struct TypingSuggestionChecker {
    public func callAsFunction(
        in textView: UITextView,
        options: TypingSuggestionOptions
    ) -> TypingSuggestion? {
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
        // valid example: "@luke_skywalker"
        // invalid example: "@luke skywalker"
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

        return TypingSuggestion(text: suggestionText, location: suggestionLocation)
    }
}

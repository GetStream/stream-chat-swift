//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChatUI
import UIKit

class SlackComposerVC: ComposerVC {
    override func updateContent() {
        super.updateContent()

        if let typingEmojiSuggestion = typingEmoji(in: composerView.inputMessageView.textView) {
            showEmojiSuggestions(for: typingEmojiSuggestion)
            return
        }
    }

    func typingEmoji(in textView: UITextView) -> TypingSuggestion? {
        let suggestionOptions = TypingSuggestionOptions(
            symbol: ":",
            minimumRequiredCharacters: 2
        )

        let typingSuggestion = typingSuggestionChecker(in: textView, options: suggestionOptions)
        return typingSuggestion
    }

    func showEmojiSuggestions(for typingSuggestion: TypingSuggestion) {
        print("Show suggestion for: \(typingSuggestion.text) in: \(typingSuggestion.location)")
    }
}

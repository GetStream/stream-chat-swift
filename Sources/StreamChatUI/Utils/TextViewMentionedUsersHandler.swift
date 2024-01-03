//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The component responsible to get the tapped mentioned user in a `UITextView`.
class TextViewMentionedUsersHandler {
    /// Get the tapped mentioned user in a text view.
    /// - Parameters:
    ///   - textView: The `UITextView` being tapped.
    ///   - characterRange: The location where the tap was performed.
    ///   - mentionedUsers: The current mentioned users in the message.
    /// - Returns: The `ChatUser` in case it tapped a mentioned user.
    func mentionedUserTapped(
        on textView: UITextView,
        in characterRange: NSRange,
        with mentionedUsers: Set<ChatUser>
    ) -> ChatUser? {
        guard let text = textView.text,
              let range = Range(characterRange, in: text)
        else {
            return nil
        }

        let mention = String(text[range])
        return mentionedUsers.first(where: {
            let name = $0.name ?? $0.id
            return mention.contains(name)
        })
    }
}

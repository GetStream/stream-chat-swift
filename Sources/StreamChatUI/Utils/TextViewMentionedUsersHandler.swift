//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class TextViewMentionedUsersHandler {
    open func mentionedUserTapped(
        on textView: UITextView,
        in characterRange: NSRange,
        withMentionedUsers mentionedUsers: Set<ChatUser>
    ) -> ChatUser? {
        guard let text = textView.text,
              let range = Range(characterRange, in: text)
        else {
            return nil
        }
        let string = String(text[range].replacingOccurrences(of: "@", with: ""))
        let user = mentionedUsers.first(where: { $0.name == string })
        return user
    }
}

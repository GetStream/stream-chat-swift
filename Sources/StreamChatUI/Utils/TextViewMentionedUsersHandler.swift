//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class TextViewMentionedUsersHandler {
    var onMentionedUserTap: ((ChatUser?) -> Void)?
    
    open func handleInteraction(
        on textView: UITextView,
        in characterRange: NSRange,
        withMentionedUsers mentionedUsers: Set<ChatUser>
    ) {
        guard let text = textView.text,
              let range = Range(characterRange, in: text)
        else { return }
        let string = String(text[range].replacingOccurrences(of: "@", with: ""))
        let user = mentionedUsers.first(where: { $0.name == string })
        onMentionedUserTap?(user)
    }
}

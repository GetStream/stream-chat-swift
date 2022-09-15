//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatUI
import UIKit

class TextViewUserMentionsHandler_Mock: TextViewMentionedUsersHandler {
    var mockMentionedUser: ChatUser?

    override func mentionedUserTapped(
        on textView: UITextView,
        in characterRange: NSRange,
        with mentionedUsers: Set<ChatUser>
    ) -> ChatUser? {
        mockMentionedUser
    }
}

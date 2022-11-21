//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
@testable import StreamChatUI

class ChatMessageContentViewDelegate_Mock: ChatMessageContentViewDelegate {
    var messageContentViewDidTapOnMentionedUserCallCount = 0
    var tappedMentionedUser: ChatUser?

    func messageContentViewDidTapOnMentionedUser(_ mentionedUser: ChatUser) {
        messageContentViewDidTapOnMentionedUserCallCount += 1
        tappedMentionedUser = mentionedUser
    }

    func messageContentViewDidTapOnErrorIndicator(_ indexPath: IndexPath?) {
        // TODO:
    }

    func messageContentViewDidTapOnThread(_ indexPath: IndexPath?) {
        // TODO:
    }

    func messageContentViewDidTapOnQuotedMessage(_ quotedMessage: ChatMessage) {
        // TODO:
    }

    func messageContentViewDidTapOnAvatarView(_ indexPath: IndexPath?) {
        // TODO:
    }

    func messageContentViewDidTapOnReactionsView(_ indexPath: IndexPath?) {
        // TODO:
    }
}

//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
@testable import StreamChatUI

class ChatMessageContentViewDelegate_Mock: ChatMessageContentViewDelegate {
    var messageContentViewDidTapOnMentionedUserCallCount = 0
    var tappedMentionedUser: ChatUser?

    var messageContentViewDidTapOnQuotedMessageCallCount = 0
    var tappedQuotedMessage: ChatMessage?

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
        messageContentViewDidTapOnQuotedMessageCallCount += 1
        tappedQuotedMessage = quotedMessage
    }

    func messageContentViewDidTapOnAvatarView(_ indexPath: IndexPath?) {
        // TODO:
    }

    func messageContentViewDidTapOnReactionsView(_ indexPath: IndexPath?) {
        // TODO:
    }
}

//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
@testable import StreamChatUI
import XCTest

class ChatMessageListRouter_Mock: ChatMessageListRouter {
    var showMessageActionsPopUpCallCount = 0
    var showMessageActionsPopUpCalledWith: (
        messageContentView: ChatMessageContentView,
        messageActionsController: ChatMessageActionsVC,
        messageReactionsController: ChatMessageReactionsPickerVC?
    )?

    override func showMessageActionsPopUp(
        messageContentView: ChatMessageContentView,
        messageActionsController: ChatMessageActionsVC,
        messageReactionsController: ChatMessageReactionsPickerVC?
    ) {
        showMessageActionsPopUpCalledWith = (messageContentView, messageActionsController, messageReactionsController)
        showMessageActionsPopUpCallCount += 1
    }

    var showThreadCallCount = 0
    var showThreadCalledWith: (parentMessageId: MessageId, replyId: MessageId?, cid: ChannelId)?

    override func showThread(messageId: MessageId, cid: ChannelId, client: ChatClient) {
        showThreadCallCount += 1
        showThreadCalledWith = (messageId, nil, cid)
    }

    override func showThread(messageId: MessageId, at replyId: MessageId?, cid: ChannelId, client: ChatClient) {
        showThreadCallCount += 1
        showThreadCalledWith = (messageId, replyId, cid)
    }
}

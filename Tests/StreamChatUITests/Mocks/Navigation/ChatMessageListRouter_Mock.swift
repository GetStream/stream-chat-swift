//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamChat
@testable import StreamChatUI
import XCTest

class ChatMessageListRouter_Mock: ChatMessageListRouter {
    var showMessageActionsPopUpCallCount = 0

    override func showMessageActionsPopUp(
        messageContentView: ChatMessageContentView,
        messageActionsController: ChatMessageActionsVC,
        messageReactionsController: ChatMessageReactionsPickerVC?
    ) {
        showMessageActionsPopUpCallCount += 1
    }
}

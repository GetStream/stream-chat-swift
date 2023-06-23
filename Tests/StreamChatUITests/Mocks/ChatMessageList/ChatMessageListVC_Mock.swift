//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatUI
import UIKit

class ChatMessageListVC_Mock: ChatMessageListVC {
    var scrollToOldestMessageCallCount = 0
    override func scrollToOldestMessage(animated: Bool = true) {
        scrollToOldestMessageCallCount += 1
    }

    var jumpToMessageCallCount = 0
    override func jumpToMessage(id: MessageId, onHighlight: ((IndexPath) -> Void)? = nil) {
        jumpToMessageCallCount += 1
    }
}

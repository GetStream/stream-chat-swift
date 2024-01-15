//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatUI
import UIKit

class ChatMessageListVC_Mock: ChatMessageListVC {
    var scrollToTopCallCount = 0
    override func scrollToTop(animated: Bool = true) {
        scrollToTopCallCount += 1
    }

    var jumpToMessageCallCount = 0
    var jumpToMessageCalledWith: (id: MessageId, animated: Bool, onHighlight: ((IndexPath) -> Void)?)?
    override func jumpToMessage(id: MessageId, animated: Bool, onHighlight: ((IndexPath) -> Void)? = nil) {
        jumpToMessageCallCount += 1
        jumpToMessageCalledWith = (id: id, animated: animated, onHighlight: onHighlight)
    }

    var jumpToUnreadMessageCallCount = 0
    override func jumpToUnreadMessage(animated: Bool = true, onHighlight: ((IndexPath) -> Void)? = nil) {
        jumpToUnreadMessageCallCount += 1
    }
}

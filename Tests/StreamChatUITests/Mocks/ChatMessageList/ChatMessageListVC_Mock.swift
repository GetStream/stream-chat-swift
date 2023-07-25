//
// Copyright © 2023 Stream.io Inc. All rights reserved.
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
    override func jumpToMessage(id: MessageId, onHighlight: ((IndexPath) -> Void)? = nil) {
        jumpToMessageCallCount += 1
    }
}

//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatUI
import UIKit

class SwipeToReplyGestureHandler_Mock: SwipeToReplyGestureHandler {
    var handleCallCount = 0
    override func handle(gesture: UIPanGestureRecognizer) {
        handleCallCount += 1
    }
}

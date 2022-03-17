//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

// A concrete `ChatUserControllerDelegate` implementation allowing capturing the delegate calls
final class TestChatUserControllerDelegate: QueueAwareDelegate, ChatUserControllerDelegate {
    @Atomic var state: DataController.State?
    @Atomic var didUpdateUser_change: EntityChange<ChatUser>?

    func controller(_ controller: DataController, didChangeState state: DataController.State) {
        validateQueue()
        self.state = state
    }

    func userController(_ controller: ChatUserController, didUpdateUser change: EntityChange<ChatUser>) {
        validateQueue()
        didUpdateUser_change = change
    }
}

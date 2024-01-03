//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

// A concrete `ChatUserControllerDelegate` implementation allowing capturing the delegate calls
final class ChatUserController_Delegate: QueueAwareDelegate, ChatUserControllerDelegate {
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

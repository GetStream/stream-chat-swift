//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

// A concrete `UserListControllerDelegate` implementation allowing capturing the delegate calls
final class UserListController_Delegate: QueueAwareDelegate, ChatUserListControllerDelegate {
    @Atomic var state: DataController.State?
    @Atomic var didChangeUsers_changes: [ListChange<ChatUser>]?

    func controller(_ controller: DataController, didChangeState state: DataController.State) {
        self.state = state
        validateQueue()
    }

    func controller(
        _ controller: ChatUserListController,
        didChangeUsers changes: [ListChange<ChatUser>]
    ) {
        didChangeUsers_changes = changes
        validateQueue()
    }
}

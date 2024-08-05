//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import XCTest

// A concrete `UserControllerDelegate` implementation allowing capturing the delegate calls
final class UserController_Delegate: QueueAwareDelegate, CurrentChatUserControllerDelegate {
    @Atomic var state: DataController.State?
    @Atomic var didChangeCurrentUser_change: EntityChange<CurrentChatUser>?
    @Atomic var didChangeCurrentUserUnreadCount_count: UnreadCount?
    let didChangeCurrentUserUnreadCountExpectation = XCTestExpectation()

    func controller(_ controller: DataController, didChangeState state: DataController.State) {
        self.state = state
        validateQueue()
    }

    func currentUserController(
        _ controller: CurrentChatUserController,
        didChangeCurrentUser change: EntityChange<CurrentChatUser>
    ) {
        didChangeCurrentUser_change = change
        validateQueue()
    }

    func currentUserController(_ controller: CurrentChatUserController, didChangeCurrentUserUnreadCount count: UnreadCount) {
        didChangeCurrentUserUnreadCount_count = count
        validateQueue()
        didChangeCurrentUserUnreadCountExpectation.fulfill()
    }
}

//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

extension ChatUserListController {
    /// A publisher emitting a new value every time the state of the controller changes.
    public var statePublisher: AnyPublisher<DataController.State, Never> {
        startUserListObserverIfNeeded()
        return stateSubject.keepAlive(self)
    }

    /// A publisher emitting a new value every time the list of the users matching the query changes.
    public var usersChangesPublisher: AnyPublisher<[ListChange<ChatUser>], Never> {
        startUserListObserverIfNeeded()
        return usersChangesSubject.keepAlive(self)
    }
}

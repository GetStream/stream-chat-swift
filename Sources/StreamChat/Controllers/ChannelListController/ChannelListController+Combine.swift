//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

extension ChatChannelListController {
    /// A publisher emitting a new value every time the state of the controller changes.
    public var statePublisher: AnyPublisher<DataController.State, Never> {
        startChannelListObserverIfNeeded()
        return stateSubject.keepAlive(self)
    }

    /// A publisher emitting a new value every time the list of the channels matching the query changes.
    public var channelsChangesPublisher: AnyPublisher<[ListChange<ChatChannel>], Never> {
        startChannelListObserverIfNeeded()
        return channelsChangesSubject.keepAlive(self)
    }
}

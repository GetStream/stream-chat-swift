//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import XCTest

// A concrete `ChatChannelWatcherListControllerDelegate` implementation allowing capturing the delegate calls
final class TestChatChannelWatcherListControllerDelegate: QueueAwareDelegate, ChatChannelWatcherListControllerDelegate {
    @Atomic var state: DataController.State?
    @Atomic var didUpdateWatchers_changes: [ListChange<ChatUser>]?

    func controller(_ controller: DataController, didChangeState state: DataController.State) {
        validateQueue()
        self.state = state
    }

    func channelWatcherListController(
        _ controller: ChatChannelWatcherListController,
        didChangeWatchers changes: [ListChange<ChatUser>]
    ) {
        validateQueue()
        didUpdateWatchers_changes = changes
    }
}

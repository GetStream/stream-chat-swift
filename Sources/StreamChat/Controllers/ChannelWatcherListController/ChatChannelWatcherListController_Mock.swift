//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

/// A mock for `ChatChannelWatcherListController`.
final class ChatChannelWatcherListControllerMock: ChatChannelWatcherListController {
    @Atomic var watchers_simulated: [ChatUser]?
    override var watchers: LazyCachedMapCollection<ChatUser> {
        watchers_simulated.map { $0.lazyCachedMap { $0 } } ?? super.watchers
    }
    
    @Atomic var state_simulated: DataController.State?
    override var state: DataController.State {
        get { state_simulated ?? super.state }
        set { super.state = newValue }
    }
}

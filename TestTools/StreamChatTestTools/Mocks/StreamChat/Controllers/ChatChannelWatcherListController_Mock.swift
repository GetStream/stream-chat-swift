//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

/// A mock for `ChatChannelWatcherListController`.
final class ChatChannelWatcherListController_Mock: ChatChannelWatcherListController, @unchecked Sendable {
    @Atomic var watchers_simulated: [ChatUser]?
    override var watchers: [ChatUser] {
        watchers_simulated ?? super.watchers
    }

    @Atomic var state_simulated: DataController.State?
    override var state: DataController.State {
        get { state_simulated ?? super.state }
        set { super.state = newValue }
    }
}

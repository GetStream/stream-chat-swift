//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import XCTest

final class ChannelListController_Mock: ChatChannelListController {
    @Atomic var synchronize_called = false
    var synchronizeCallCount = 0

    var channels_simulated: [ChatChannel]?
    override var channels: LazyCachedMapCollection<ChatChannel> {
        channels_simulated.map { $0.lazyCachedMap { $0 } } ?? super.channels
    }

    var state_simulated: DataController.State?
    override var state: DataController.State {
        get { state_simulated ?? super.state }
        set { super.state = newValue }
    }

    init() {
        super.init(query: .init(filter: .notEqual("cid", to: "")), client: .mock)
    }

    override func synchronize(_ completion: ((Error?) -> Void)? = nil) {
        synchronize_called = true
        synchronizeCallCount += 1 
    }
}

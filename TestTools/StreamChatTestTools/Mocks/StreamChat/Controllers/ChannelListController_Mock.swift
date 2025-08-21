//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import XCTest

final class ChannelListController_Mock: ChatChannelListController, @unchecked Sendable {
    @Atomic var synchronize_called = false
    @Atomic var synchronize_callCount = 0
    @Atomic var synchronize_completion: (@MainActor(Error?) -> Void)?

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

    override func synchronize(_ completion: (@MainActor(Error?) -> Void)? = nil) {
        synchronize_callCount += 1
        synchronize_completion = completion
    }
}

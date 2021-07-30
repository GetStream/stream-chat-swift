//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

public class ChatChannelListController_Mock: ChatChannelListController {
    public var loadNextChannelsIsCalled = false

    /// Creates a new mock instance of `ChatChannelListController`.
    public static func mock() -> ChatChannelListController_Mock<ExtraData> {
        .init(query: .init(filter: .equal(.memberCount, to: 0)), client: .mock())
    }
    
    public private(set) var channels_mock: [ChatChannel]?
    override public var channels: LazyCachedMapCollection<ChatChannel> {
        channels_mock.map { $0.lazyCachedMap { $0 } } ?? super.channels
    }
    
    public private(set) var state_mock: State?
    override public var state: DataController.State {
        get { state_mock ?? super.state }
        set { super.state = newValue }
    }

    override public func loadNextChannels(limit: Int, completion: ((Error?) -> Void)?) {
        loadNextChannelsIsCalled = true
    }
}

public extension ChatChannelListController_Mock {
    /// Simulates the initial conditions. Setting these values doesn't trigger any observer callback.
    func simulateInitial(channels: [ChatChannel], state: DataController.State) {
        channels_mock = channels
        state_mock = state
    }
    
    /// Simulates changes in the channels array. Observers are notified with the provided `changes` value.
    func simulate(channels: [ChatChannel], changes: [ListChange<ChatChannel>]) {
        channels_mock = channels
        delegateCallback {
            $0.controller(self, didChangeChannels: changes)
        }
    }
    
    /// Simulates changes of `state`. Observers are notified with the new value.
    func simulate(state: DataController.State) {
        state_mock = state
        delegateCallback {
            $0.controller(self, didChangeState: state)
        }
    }
}

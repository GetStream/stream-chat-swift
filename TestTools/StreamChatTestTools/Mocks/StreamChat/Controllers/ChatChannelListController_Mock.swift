//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

class ChatChannelListController_Mock: ChatChannelListController, Spy {
    let spyState = SpyState()
    var loadNextChannelsIsCalled = false
    var loadNextChannelsCallCount = 0
    var resetChannelsQueryResult: Result<(synchedAndWatched: [ChatChannel], unwanted: Set<ChannelId>), Error>?
    var refreshLoadedChannelsResult: Result<Set<ChannelId>, any Error>?

    /// Creates a new mock instance of `ChatChannelListController`.
    static func mock(client: ChatClient? = nil) -> ChatChannelListController_Mock {
        .init(query: .init(filter: .equal(.memberCount, to: 0)), client: client ?? .mock())
    }

    var channels_mock: [ChatChannel]?
    override var channels: LazyCachedMapCollection<ChatChannel> {
        channels_mock.map { $0.lazyCachedMap { $0 } } ?? super.channels
    }

    var state_mock: State?
    override var state: DataController.State {
        get { state_mock ?? super.state }
        set { super.state = newValue }
    }

    override func loadNextChannels(limit: Int?, completion: ((Error?) -> Void)?) {
        loadNextChannelsCallCount += 1
        loadNextChannelsIsCalled = true
    }

    override func refreshLoadedChannels(completion: @escaping (Result<Set<ChannelId>, any Error>) -> Void) {
        record()
        refreshLoadedChannelsResult.map(completion)
    }
    
    override func resetQuery(
        watchedAndSynchedChannelIds: Set<ChannelId>,
        synchedChannelIds: Set<ChannelId>,
        completion: @escaping (Result<(synchedAndWatched: [ChatChannel], unwanted: Set<ChannelId>), Error>) -> Void
    ) {
        record()
        resetChannelsQueryResult.map(completion)
    }
}

extension ChatChannelListController_Mock {
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

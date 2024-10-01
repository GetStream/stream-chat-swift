//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

/// Mock implementation of ChannelListUpdater
final class ChannelListUpdater_Spy: ChannelListUpdater, Spy {
    let spyState = SpyState()

    @Atomic var update_queries: [ChannelListQuery] = []
    @Atomic var update_completion: ((Result<[ChatChannel], Error>) -> Void)?
    @Atomic var update_completion_result: Result<[ChatChannel], Error>?

    @Atomic var fetch_queries: [ChannelListQuery] = []
    @Atomic var fetch_completion: ((Result<ChannelListPayload, Error>) -> Void)?

    var resetChannelsQueryResult: Result<(synchedAndWatched: [ChatChannel], unwanted: Set<ChannelId>), Error>?

    @Atomic var markAllRead_completion: ((Error?) -> Void)?

    var startWatchingChannels_callCount = 0
    @Atomic var startWatchingChannels_cids: [ChannelId] = []
    @Atomic var startWatchingChannels_completion: ((Error?) -> Void)?
    @Atomic var startWatchingChannels_completion_result: Result<Void, Error>?
    
    var link_callCount = 0
    var link_completion: ((Error?) -> Void)?
    @Atomic var link_completion_result: Result<Void, Error>?
    
    var unlink_callCount = 0
    @Atomic var unlink_completion_result: Result<Void, Error>?

    func cleanUp() {
        update_queries.removeAll()
        update_completion = nil
        update_completion_result = nil

        fetch_queries.removeAll()
        fetch_completion = nil

        link_completion_result = nil
        
        markAllRead_completion = nil

        startWatchingChannels_cids.removeAll()
        startWatchingChannels_completion = nil
        startWatchingChannels_completion_result = nil
        
        unlink_completion_result = nil
    }

    override func update(
        channelListQuery: ChannelListQuery,
        completion: ((Result<[ChatChannel], Error>) -> Void)? = nil
    ) {
        _update_queries.mutate { $0.append(channelListQuery) }
        update_completion = completion
        update_completion_result?.invoke(with: completion)
    }

    override func markAllRead(completion: ((Error?) -> Void)? = nil) {
        markAllRead_completion = completion
    }

    override func fetch(
        channelListQuery: ChannelListQuery,
        completion: @escaping (Result<ChannelListPayload, Error>) -> Void
    ) {
        _fetch_queries.mutate { $0.append(channelListQuery) }
        fetch_completion = completion
    }

    override func resetChannelsQuery(
        for query: ChannelListQuery,
        pageSize: Int,
        watchedAndSynchedChannelIds: Set<ChannelId>,
        synchedChannelIds: Set<ChannelId>,
        completion: @escaping (Result<(synchedAndWatched: [ChatChannel], unwanted: Set<ChannelId>), Error>) -> Void
    ) {
        record()
        resetChannelsQueryResult.map(completion)
    }

    override func link(
        channel: ChatChannel,
        with query: ChannelListQuery,
        completion: ((Error?) -> Void)? = nil
    ) {
        link_callCount += 1
        link_completion = completion
        link_completion_result?.invoke(with: completion)
    }

    override func unlink(
        channel: ChatChannel,
        with query: ChannelListQuery,
        completion: ((Error?) -> Void)? = nil
    ) {
        unlink_callCount += 1
        unlink_completion_result?.invoke(with: completion)
    }

    override func startWatchingChannels(withIds ids: [ChannelId], completion: ((Error?) -> Void)?) {
        startWatchingChannels_callCount += 1
        startWatchingChannels_cids = ids
        startWatchingChannels_completion = completion
        startWatchingChannels_completion_result?.invoke(with: completion)
    }
}

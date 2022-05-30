//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

/// Mock implementation of ChannelListUpdater
final class ChannelListUpdater_Spy: ChannelListUpdater, Spy {
    var recordedFunctions: [String] = []

    @Atomic var update_queries: [ChannelListQuery] = []
    @Atomic var update_completion: ((Result<[ChatChannel], Error>) -> Void)?
    
    @Atomic var fetch_queries: [ChannelListQuery] = []
    @Atomic var fetch_completion: ((Result<ChannelListPayload, Error>) -> Void)?

    var resetChannelsQueryResult: Result<(synchedAndWatched: [ChatChannel], unwanted: Set<ChannelId>), Error>?
    
    @Atomic var markAllRead_completion: ((Error?) -> Void)?

    @Atomic var startWatchingChannels_cids: [ChannelId] = []
    @Atomic var startWatchingChannels_completion: ((Error?) -> Void)?
    
    func cleanUp() {
        update_queries.removeAll()
        update_completion = nil
        
        fetch_queries.removeAll()
        fetch_completion = nil
        
        markAllRead_completion = nil
        
        startWatchingChannels_cids.removeAll()
        startWatchingChannels_completion = nil
    }
    
    override func update(
        channelListQuery: ChannelListQuery,
        completion: ((Result<[ChatChannel], Error>) -> Void)? = nil
    ) {
        _update_queries.mutate { $0.append(channelListQuery) }
        update_completion = completion
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

    override func startWatchingChannels(withIds ids: [ChannelId], completion: ((Error?) -> Void)?) {
        startWatchingChannels_cids = ids
        startWatchingChannels_completion = completion
    }
}

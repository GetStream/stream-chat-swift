//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

/// Mock implementation of ChannelListUpdater
final class ChannelListUpdater_Spy: ChannelListUpdater, Spy, @unchecked Sendable {
    let spyState = SpyState()

    @Atomic var update_queries: [ChannelListQuery] = []
    @Atomic var update_completion: (@Sendable (Result<[ChatChannel], Error>) -> Void)?
    @Atomic var update_completion_result: Result<[ChatChannel], Error>?

    @Atomic var fetch_queries: [ChannelListQuery] = []
    @Atomic var fetch_completion: (@Sendable (Result<ChannelListPayload, Error>) -> Void)?

    @Atomic var refreshLoadedChannelsResult: Result<Set<ChannelId>, Error>?

    @Atomic var queryGroupedChannels_callCount = 0
    @Atomic var queryGroupedChannels_paginations: [GroupedChannelsPagination?] = []
    @Atomic var queryGroupedChannels_result: Result<GroupedChannels, Error>?

    @Atomic var markAllRead_completion: (@Sendable (Error?) -> Void)?

    var startWatchingChannels_callCount = 0
    @Atomic var startWatchingChannels_cids: [ChannelId] = []
    @Atomic var startWatchingChannels_completion: (@Sendable (Error?) -> Void)?
    var startWatchingChannels_completion_success = false

    var link_callCount = 0
    var link_completion: (@Sendable (Error?) -> Void)?

    var unlink_callCount = 0

    func cleanUp() {
        update_queries.removeAll()
        update_completion = nil
        update_completion_result = nil

        fetch_queries.removeAll()
        fetch_completion = nil

        queryGroupedChannels_callCount = 0
        queryGroupedChannels_paginations.removeAll()
        queryGroupedChannels_result = nil
        markAllRead_completion = nil

        startWatchingChannels_cids.removeAll()
        startWatchingChannels_completion = nil
        startWatchingChannels_completion_success = false
    }

    override func update(
        channelListQuery: ChannelListQuery,
        completion: (@Sendable (Result<[ChatChannel], Error>) -> Void)? = nil
    ) {
        _update_queries.mutate { $0.append(channelListQuery) }
        update_completion = completion
        update_completion_result?.invoke(with: completion)
    }

    override func markAllRead(completion: (@Sendable (Error?) -> Void)? = nil) {
        markAllRead_completion = completion
    }

    override func fetch(
        channelListQuery: ChannelListQuery,
        completion: @escaping @Sendable (Result<ChannelListPayload, Error>) -> Void
    ) {
        _fetch_queries.mutate { $0.append(channelListQuery) }
        fetch_completion = completion
    }

    override func refreshLoadedChannels(
        for query: ChannelListQuery,
        channelCount: Int,
        completion: @escaping @Sendable (Result<Set<ChannelId>, any Error>) -> Void
    ) {
        record()
        refreshLoadedChannelsResult?.invoke(with: completion)
    }

    override func paginationCursor(
        for groupKey: String,
        completion: @escaping @Sendable (Result<String?, Error>) -> Void
    ) {
        do {
            let cursor = try database.readAndWait { session in
                session.channelListQuery(ChannelListQuery(groupKey: groupKey))?.next
            }
            completion(.success(cursor))
        } catch {
            completion(.failure(error))
        }
    }

    override func queryGroupedChannels(
        groupPagination: GroupedChannelsPagination?,
        limit: Int?,
        watch: Bool,
        presence: Bool,
        completion: @escaping @Sendable (Result<GroupedChannels, Error>) -> Void
    ) {
        _queryGroupedChannels_callCount.mutate { $0 += 1 }
        _queryGroupedChannels_paginations.mutate { $0.append(groupPagination) }
        if let result = queryGroupedChannels_result {
            DispatchQueue.main.async {
                completion(result)
            }
        } else {
            super.queryGroupedChannels(
                groupPagination: groupPagination,
                limit: limit,
                watch: watch,
                presence: presence,
                completion: completion
            )
        }
    }

    override func link(
        channel: ChatChannel,
        with query: ChannelListQuery,
        completion: (@Sendable (Error?) -> Void)? = nil
    ) {
        link_callCount += 1
        link_completion = completion
    }

    override func unlink(
        channel: ChatChannel,
        with query: ChannelListQuery,
        completion: (@Sendable (Error?) -> Void)? = nil
    ) {
        unlink_callCount += 1
    }

    override func startWatchingChannels(withIds ids: [ChannelId], completion: (@Sendable (Error?) -> Void)?) {
        startWatchingChannels_callCount += 1
        startWatchingChannels_cids = ids
        if startWatchingChannels_completion_success {
            completion?(nil)
        } else {
            startWatchingChannels_completion = completion
        }
    }
}

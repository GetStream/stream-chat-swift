//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat

@available(iOS 13.0, *)
extension ChannelListUpdater {
    func link(channel: ChatChannel, with query: ChannelListQuery) async throws {
        try await withCheckedThrowingContinuation { continuation in
            link(channel: channel, with: query) { error in
                continuation.resume(with: error)
            }
        }
    }

    func startWatchingChannels(withIds ids: [ChannelId]) async throws {
        try await withCheckedThrowingContinuation { continuation in
            startWatchingChannels(withIds: ids) { error in
                continuation.resume(with: error)
            }
        }
    }

    func unlink(channel: ChatChannel, with query: ChannelListQuery) async throws {
        try await withCheckedThrowingContinuation { continuation in
            unlink(channel: channel, with: query) { error in
                continuation.resume(with: error)
            }
        }
    }

    @discardableResult func update(channelListQuery: ChannelListQuery) async throws -> [ChatChannel] {
        try await withCheckedThrowingContinuation { continuation in
            update(channelListQuery: channelListQuery) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    // MARK: -
    
    func loadChannels(query: ChannelListQuery, pagination: Pagination) async throws -> [ChatChannel] {
        try await update(channelListQuery: query.withPagination(pagination))
    }
    
    func loadNextChannels(query: ChannelListQuery, limit: Int, loadedChannelsCount: Int) async throws -> [ChatChannel] {
        let pagination = Pagination(pageSize: limit, offset: loadedChannelsCount)
        return try await update(channelListQuery: query.withPagination(pagination))
    }
}

private extension ChannelListQuery {
    func withPagination(_ pagination: Pagination) -> Self {
        var query = self
        query.pagination = pagination
        return query
    }
}

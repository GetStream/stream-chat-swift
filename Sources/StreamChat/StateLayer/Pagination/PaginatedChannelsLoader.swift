//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
struct PaginatedChannelsLoader {
    let query: ChannelListQuery
    let chatClientConfig: ChatClientConfig
    let channelListUpdater: ChannelListUpdater
    let channelRepository: ChannelRepository
    
    func loadChannels(to state: ChatListState, pagination: Pagination) async throws -> [ChatChannel] {
        let query = self.query.withPagination(pagination)
        let payloadChannels = try await channelListUpdater.update(channelListQuery: query)
        // Optimization: remove the database fetch and instead replicate filtering and sorting defined by ChannelDTO.channelListFetchRequest(query:chatClientConfig:). Currently we can't ensure that payloadChannels is sorted the same way.
        let newSortedChannels = try await channelRepository.channels(
            for: payloadChannels.map(\.cid),
            query: query,
            config: chatClientConfig
        )
        let currentChannels = await state.value(forKeyPath: \.channels)
        let merged = currentChannels.uniquelyMerged(newSortedChannels, sorting: query.sort)
        await state.setSortedChannels(merged, hasLoadedAll: payloadChannels.count < pagination.pageSize)
        
        return payloadChannels
    }
    
    func loadMoreChannels(to state: ChatListState, limit: Int? = nil) async throws -> [ChatChannel] {
        let cursor = await state.value(forKeyPath: \.channels).last?.cid.rawValue
        let pageSize = limit ?? query.pagination.pageSize
        let pagination = Pagination(pageSize: pageSize > 0 ? pageSize : .channelsPageSize, cursor: cursor)
        return try await loadChannels(to: state, pagination: pagination)
    }
}

private extension ChannelListQuery {
    func withPagination(_ pagination: Pagination) -> Self {
        var query = self
        query.pagination = pagination
        return query
    }
}

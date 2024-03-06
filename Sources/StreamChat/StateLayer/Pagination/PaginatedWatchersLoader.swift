//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// Loads paginated watches of the channel.
@available(iOS 13.0, *)
struct PaginatedWatchersLoader {
    private let cid: ChannelId
    private let channelUpdater: ChannelUpdater
    private let userRepository: UserRepository
    
    init(cid: ChannelId, channelUpdater: ChannelUpdater, userRepository: UserRepository) {
        self.cid = cid
        self.channelUpdater = channelUpdater
        self.userRepository = userRepository
    }
    
    func loadWatchers(to state: ChatState, with pagination: Pagination) async throws -> [ChatUser] {
        let query = ChannelWatcherListQuery(cid: cid, pagination: pagination)
        let payload = try await channelUpdater.watchers(for: query)
        let ids = payload.watchers?.map(\.id) ?? []
        // Optimization: skip DB fetch when chat users can be created from payload
        let newWatchers = try await userRepository.watchers(for: Set(ids), in: cid)
        let sortDescriptors = UserDTO.watcherFetchRequest(cid: cid).sortDescriptors ?? []
        let current = await state.value(forKeyPath: \.watchers)
        let result = current.uniquelyMerged(newWatchers, sortDescriptors: sortDescriptors)
        await state.setSortedWatchers(result, hasLoadedAll: ids.count < pagination.pageSize)
        return newWatchers
    }
    
    func loadMoreWatchers(to state: ChatState, limit: Int?) async throws -> [ChatUser] {
        let count = await state.value(forKeyPath: \.watchers.count)
        let pageSize = limit ?? .channelWatchersPageSize
        let pagination = Pagination(pageSize: pageSize, offset: count)
        return try await loadWatchers(to: state, with: pagination)
    }
}

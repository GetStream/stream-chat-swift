//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// An object which represents a list of `ChatChannel`s for the specified  channel query.
public class ChannelList: @unchecked Sendable {
    private let channelListUpdater: ChannelListUpdater
    private let client: ChatClient
    let query: ChannelListQuery
    @MainActor private var stateBuilder: StateBuilder<ChannelListState>

    init(
        query: ChannelListQuery,
        dynamicFilter: (@Sendable (ChatChannel) -> Bool)?,
        client: ChatClient,
        environment: Environment = .init()
    ) {
        self.client = client
        self.query = query
        let channelListUpdater = environment.channelListUpdater(
            client.databaseContainer,
            client.apiClient
        )
        self.channelListUpdater = channelListUpdater
        stateBuilder = StateBuilder {
            environment.stateBuilder(
                query,
                dynamicFilter,
                client.config,
                channelListUpdater,
                client.databaseContainer,
                client.eventNotificationCenter,
                client.channelWatcherHandler
            )
        }
    }
    
    // MARK: - Accessing the State
    
    /// An observable object representing the current state of the channel list.
    @MainActor public var state: ChannelListState { stateBuilder.state }
    
    /// Fetches the most recent state from the server and updates the local store.
    ///
    /// - Important: Loaded channels in ``ChannelListState/channels`` are reset.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func get() async throws {
        if query.groupKey == nil {
            let pagination = Pagination(pageSize: query.pagination.pageSize)
            try await loadChannels(with: pagination)
        }
        client.syncRepository.startTrackingChannelList(self)
    }

    // MARK: - Channel List Pagination

    /// Loads channels for the specified pagination parameters and updates ``ChannelListState/channels``.
    ///
    /// - Important: If the pagination offset is 0 and cursor is nil, then loaded channels are reset.
    ///
    /// - Parameter pagination: The pagination configuration which includes a limit and a cursor or an offset.
    ///
    /// - Throws: An error while communicating with the Stream API.
    /// - Returns: An array of channels for the pagination.
    @discardableResult public func loadChannels(with pagination: Pagination) async throws -> [ChatChannel] {
        if let groupKey = query.groupKey {
            let channelGroups = try await channelListUpdater.queryGroupedChannels(
                groupPagination: .init(groupKey: groupKey, next: pagination.cursor),
                limit: pagination.pageSize,
                watch: true,
                presence: true
            )
            let group = channelGroups.first { $0.groupKey == groupKey }
            await setHasLoadedAllPreviousChannels(group?.next == nil)
            guard let channelIds = group?.channelIds, !channelIds.isEmpty else { return [] }
            return try await client.databaseContainer.read { session in
                channelIds.compactMap { try? session.channel(cid: $0)?.asModel() }
            }
        } else {
            return try await channelListUpdater.loadChannels(query: query, pagination: pagination)
        }
    }

    /// Loads more channels and updates ``ChannelListState/channels``.
    ///
    /// - Parameter limit: The limit for the page size. The default limit is 20.
    ///
    /// - Throws: An error while communicating with the Stream API.
    /// - Returns: An array of loaded channels.
    @discardableResult public func loadMoreChannels(limit: Int? = nil) async throws -> [ChatChannel] {
        guard await !state.hasLoadedAllPreviousChannels else { return [] }
        let limit = limit ?? query.pagination.pageSize
        if let groupKey = query.groupKey {
            let cursor = try await channelListUpdater.paginationCursor(for: groupKey)
            guard let cursor else {
                await setHasLoadedAllPreviousChannels(true)
                return []
            }
            return try await loadChannels(with: Pagination(pageSize: limit, cursor: cursor))
        } else {
            let channels = try await loadChannels(with: Pagination(pageSize: limit, offset: await state.channels.count))
            await setHasLoadedAllPreviousChannels(channels.count < limit)
            return channels
        }
    }

    // MARK: - Internal

    func refreshLoadedChannels() async throws -> Set<ChannelId> {
        let count = await state.channels.count
        return try await channelListUpdater.refreshLoadedChannels(for: query, channelCount: count)
    }

    @MainActor private func setHasLoadedAllPreviousChannels(_ hasLoadedAllPreviousChannels: Bool) {
        state.hasLoadedAllPreviousChannels = hasLoadedAllPreviousChannels
    }
}

extension ChannelList {
    struct Environment: Sendable {
        var channelListUpdater: @Sendable (
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> ChannelListUpdater = { ChannelListUpdater(database: $0, apiClient: $1) }
        
        var stateBuilder: @Sendable @MainActor (
            _ query: ChannelListQuery,
            _ dynamicFilter: (@Sendable (ChatChannel) -> Bool)?,
            _ clientConfig: ChatClientConfig,
            _ channelListUpdater: ChannelListUpdater,
            _ database: DatabaseContainer,
            _ eventNotificationCenter: EventNotificationCenter,
            _ channelWatcherHandler: ChannelWatcherHandling
        ) -> ChannelListState = { @MainActor in
            ChannelListState(
                query: $0,
                dynamicFilter: $1,
                clientConfig: $2,
                channelListUpdater: $3,
                database: $4,
                eventNotificationCenter: $5,
                channelWatcherHandler: $6
            )
        }
    }
}

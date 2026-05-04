//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// An object which represents a list of `ChatChannel`s for the specified  channel query.
public class ChannelList: @unchecked Sendable {
    private let channelListUpdater: ChannelListUpdater
    private let client: ChatClient
    private let dynamicFilter: (@Sendable (ChatChannel) -> Bool)?
    let query: AllocatedUnfairLock<ChannelListQuery>
    @MainActor private var stateBuilder: StateBuilder<ChannelListState>
    
    init(
        query: ChannelListQuery,
        dynamicFilter: (@Sendable (ChatChannel) -> Bool)?,
        client: ChatClient,
        environment: Environment = .init()
    ) {
        self.client = client
        self.dynamicFilter = dynamicFilter
        self.query = AllocatedUnfairLock(query)
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
        if await state.consumeShouldSkipInitialRemoteUpdate() {
            return
        }
        let pagination = Pagination(pageSize: query.value.pagination.pageSize)
        try await loadChannels(with: pagination)
        client.syncRepository.startTrackingChannelList(self)
    }

    /// Prefills the channel list with an initial channel list snapshot and skips the first remote
    /// `queryChannels` request when ``get()`` is called afterwards.
    ///
    /// The prefetched channels are persisted in the local storage and linked only to this channel
    /// list query, so pagination, local observation and offline refresh keep working.
    public func prefill(group: GroupedChannelsGroup) async throws {
        let prefilledChannels = dynamicFilter.map { runtimeFilter in
            group.channels.filter(runtimeFilter)
        } ?? group.channels
        let prefilledGroup = GroupedChannelsGroup(
            groupKey: group.groupKey,
            channels: prefilledChannels,
            unreadChannels: group.unreadChannels
        )
        let updatedQuery = query.withLock {
            $0.groupKey = group.groupKey
            return $0
        }

        _ = try await channelListUpdater.prefill(group: prefilledGroup, for: updatedQuery)
        await resetStateAfterPrefill(query: updatedQuery, prefilledChannelsCount: prefilledChannels.count)
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
        return try await channelListUpdater.loadChannels(query: query.value, pagination: pagination)
    }
    
    /// Loads more channels and updates ``ChannelListState/channels``.
    ///
    /// - Parameter limit: The limit for the page size. The default limit is 20.
    ///
    /// - Throws: An error while communicating with the Stream API.
    /// - Returns: An array of loaded channels.
    @discardableResult public func loadMoreChannels(limit: Int? = nil) async throws -> [ChatChannel] {
        let query = query.value
        let limit = limit ?? query.pagination.pageSize
        let count = await state.channels.count
        return try await channelListUpdater.loadNextChannels(
            query: query,
            limit: limit,
            loadedChannelsCount: count
        )
    }
    
    // MARK: - Internal
    
    func refreshLoadedChannels() async throws -> Set<ChannelId> {
        let query = query.value
        let count = await state.channels.count
        return try await channelListUpdater.refreshLoadedChannels(for: query, channelCount: count)
    }

    @MainActor private func resetStateAfterPrefill(query: ChannelListQuery, prefilledChannelsCount: Int) {
        state.reset(
            query: query,
            minimumFetchLimit: prefilledChannelsCount
        )
        state.skipNextInitialRemoteUpdate()
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

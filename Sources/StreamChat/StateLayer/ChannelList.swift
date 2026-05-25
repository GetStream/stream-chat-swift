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
    
    /// Fetches the first page of channels from the server and registers the list for reconnect sync.
    ///
    /// - For filter-based lists, ``ChannelListState/channels`` is reset to the first page returned
    ///   by the channels endpoint.
    /// - For group-based lists (created via ``ChatClient/makeChannelList(with:)-(String)``), the
    ///   first page is fetched from the grouped endpoint with no cursor; the request inherits the
    ///   `watch` / `presence` flags persisted by the most recent
    ///   ``ChatClient/queryGroupedChannels(groups:limit:presence:watch:)`` call for the group.
    ///
    /// Subsequent pages are loaded via ``loadMoreChannels(limit:)``.
    ///
    /// - Important: For group-based lists, prefer `get()` only when fetching the first page for a *single* group
    /// in isolation. When the app needs first pages for multiple groups, call
    /// ``ChatClient/queryGroupedChannels(groups:limit:presence:watch:)`` instead — it returns every group
    /// in one request, which is significantly more efficient than calling `get()` per `ChannelList`.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func get() async throws {
        let pagination = Pagination(pageSize: query.pagination.pageSize)
        try await loadChannels(with: pagination)
        client.syncRepository.startTrackingChannelList(self)
    }

    // MARK: - Channel List Pagination

    /// Loads channels for the specified pagination parameters and updates ``ChannelListState/channels``.
    ///
    /// - Important: For filter-based lists, loaded channels are reset when the pagination offset is 0 and
    /// the cursor is nil. For group-based lists, only ``Pagination/cursor`` is used — the offset is ignored —
    /// and the grouped endpoint controls the page contents.
    ///
    /// - Parameter pagination: The pagination configuration which includes a limit and a cursor or an offset.
    ///
    /// - Throws: An error while communicating with the Stream API.
    /// - Returns: An array of channels for the pagination.
    @discardableResult public func loadChannels(with pagination: Pagination) async throws -> [ChatChannel] {
        if let groupKey = query.groupKey {
            let state = try await channelListUpdater.paginationState(for: groupKey)
            let perGroup = GroupedQueryChannelsRequestGroup(
                limit: pagination.pageSize != .unsetPageSize ? pagination.pageSize : nil,
                next: pagination.cursor
            )
            let channelGroups = try await channelListUpdater.queryGroupedChannels(
                groups: [groupKey: perGroup],
                limit: nil,
                watch: state.watch ?? false,
                presence: state.presence ?? false
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
    /// - Parameter limit: The limit for the page size. For filter-based lists the default is ``Int/channelsPageSize`` (20);
    /// for group-based lists, the backend chooses the default and `limit` is forwarded only when provided.
    ///
    /// - Throws: An error while communicating with the Stream API.
    /// - Returns: An array of loaded channels.
    @discardableResult public func loadMoreChannels(limit: Int? = nil) async throws -> [ChatChannel] {
        guard await !state.hasLoadedAllPreviousChannels else { return [] }
        if let groupKey = query.groupKey {
            let paginationState = try await channelListUpdater.paginationState(for: groupKey)
            guard let cursor = paginationState.next else {
                await setHasLoadedAllPreviousChannels(true)
                return []
            }
            return try await loadChannels(with: Pagination(pageSize: limit ?? .unsetPageSize, cursor: cursor))
        } else {
            let resolved = limit ?? query.pagination.pageSize
            let channels = try await loadChannels(with: Pagination(pageSize: resolved, offset: await state.channels.count))
            await setHasLoadedAllPreviousChannels(channels.count < resolved)
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

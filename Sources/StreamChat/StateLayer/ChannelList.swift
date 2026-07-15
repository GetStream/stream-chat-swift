//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// An object which represents a list of `ChatChannel`s for the specified  channel query.
public class ChannelList: @unchecked Sendable {
    private let channelListUpdater: ChannelListUpdater
    private let client: ChatClient
    private let query: ChannelListQuery
    private let dynamicFilter: (@Sendable (ChatChannel) -> Bool)?
    @MainActor private var stateBuilder: StateBuilder<ChannelListState>
    let groupKey: String?

    /// A serial queue backing the non-isolated ``ChannelListObservableState`` used by controllers.
    private let backgroundStateQueue = DispatchQueue(
        label: "io.getstream.channel-list-background-state",
        target: .global()
    )
    private var _backgroundState: ChannelListObservableState?

    init(
        query: ChannelListQuery,
        dynamicFilter: (@Sendable (ChatChannel) -> Bool)?,
        client: ChatClient,
        environment: Environment = .init()
    ) {
        self.client = client
        self.query = query
        self.dynamicFilter = dynamicFilter
        self.groupKey = query.groupKey
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

    // MARK: - Non-Isolated Background State (Controller Support)

    /// Provides serialized access to the non-isolated ``ChannelListObservableState``.
    ///
    /// The state and the `actions` closure both run on ``backgroundStateQueue``, which makes it safe
    /// to read ``ChannelListObservableState/channels`` and observe changes from non-isolated contexts
    /// (like ``ChatChannelListController``) without hopping to the main actor or blocking the database queue.
    @discardableResult
    func backgroundState<T>(_ actions: (ChannelListObservableState) -> T) -> T {
        backgroundStateQueue.sync {
            let state: ChannelListObservableState
            if let existing = _backgroundState {
                state = existing
            } else {
                state = ChannelListObservableState(
                    queue: backgroundStateQueue,
                    query: query,
                    dynamicFilter: dynamicFilter,
                    clientConfig: client.config,
                    channelListUpdater: channelListUpdater,
                    database: client.databaseContainer,
                    eventNotificationCenter: client.eventNotificationCenter,
                    channelWatcherHandler: client.channelWatcherHandler
                )
                _backgroundState = state
            }
            return actions(state)
        }
    }

    /// Fetches the most recent state from the server and updates the local store.
    ///
    /// - Important: Loaded channels in ``ChannelListState/channels`` are reset.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func get() async throws {
        let pagination = Pagination(pageSize: await state.query.pagination.pageSize)
        try await loadChannels(with: pagination)
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
        if let groupKey {
            let paginationState = try await channelListUpdater.paginationState(for: groupKey)
            let channelGroups = try await channelListUpdater.queryGroupedChannels(
                groups: [groupKey: .init(limit: pagination.pageSize > 0 ? pagination.pageSize : nil, next: pagination.cursor)],
                limit: nil,
                watch: paginationState.watch ?? true,
                presence: paginationState.presence ?? false
            )
            let group = channelGroups.first { $0.groupKey == groupKey }
            await setHasLoadedAllPreviousChannels(group?.next == nil)
            return group?.channels ?? []
        } else {
            var query = await state.query
            query.pagination = pagination
            let result = try await channelListUpdater.update(channelListQuery: query)
            if let updatedQuery = result.updatedQuery {
                await state.setQuery(updatedQuery)
            }
            return result.channels
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
        let pageSize = await state.query.pagination.pageSize
        let limit = limit ?? pageSize
        if let groupKey {
            let paginationState = try await channelListUpdater.paginationState(for: groupKey)
            guard let cursor = paginationState.next else {
                await setHasLoadedAllPreviousChannels(true)
                return []
            }
            return try await loadChannels(with: Pagination(pageSize: limit, cursor: cursor))
        } else {
            let count = await state.channels.count
            let channels = try await loadChannels(with: Pagination(pageSize: limit, offset: count))
            await setHasLoadedAllPreviousChannels(channels.isEmpty || channels.count < limit)
            return channels
        }
    }

    // MARK: - Internal

    func refreshLoadedChannels() async throws -> Set<ChannelId> {
        let count = await state.channels.count
        let query = await state.query
        return try await channelListUpdater.refreshLoadedChannels(for: query, channelCount: count)
    }

    @MainActor private func setHasLoadedAllPreviousChannels(_ hasLoadedAllPreviousChannels: Bool) {
        state.hasLoadedAllPreviousChannels = hasLoadedAllPreviousChannels
    }

    // MARK: - Controller Support

    /// Loads the first page into the non-isolated background state.
    ///
    /// - Note: Sync tracking is handled by the owning ``ChatChannelListController`` (which registers
    ///   itself via `startTrackingChannelListController`), so this method does not track the list.
    @discardableResult
    func synchronizeBackgroundState() async throws -> [ChatChannel] {
        let pageSize = backgroundState { $0.query.pagination.pageSize }
        return try await loadBackgroundStateChannels(with: Pagination(pageSize: pageSize))
    }

    /// Loads channels for the specified pagination and updates the non-isolated background state.
    @discardableResult
    func loadBackgroundStateChannels(with pagination: Pagination) async throws -> [ChatChannel] {
        if let groupKey {
            let paginationState = try await channelListUpdater.paginationState(for: groupKey)
            let channelGroups = try await channelListUpdater.queryGroupedChannels(
                groups: [groupKey: .init(limit: pagination.pageSize > 0 ? pagination.pageSize : nil, next: pagination.cursor)],
                limit: nil,
                watch: paginationState.watch ?? true,
                presence: paginationState.presence ?? false
            )
            let group = channelGroups.first { $0.groupKey == groupKey }
            backgroundState { $0.hasLoadedAllPreviousChannels = group?.next == nil }
            return group?.channels ?? []
        } else {
            var query = backgroundState { $0.query }
            query.pagination = pagination
            let result = try await channelListUpdater.update(channelListQuery: query)
            if let updatedQuery = result.updatedQuery {
                backgroundState { $0.setQuery(updatedQuery) }
            }
            return result.channels
        }
    }

    /// Loads the next page of channels into the non-isolated background state.
    @discardableResult
    func loadMoreBackgroundStateChannels(limit: Int? = nil) async throws -> [ChatChannel] {
        let (hasLoadedAll, pageSize, count) = backgroundState {
            ($0.hasLoadedAllPreviousChannels, $0.query.pagination.pageSize, $0.channels.count)
        }
        guard !hasLoadedAll else { return [] }
        let limit = limit ?? pageSize
        if let groupKey {
            let paginationState = try await channelListUpdater.paginationState(for: groupKey)
            guard let cursor = paginationState.next else {
                backgroundState { $0.hasLoadedAllPreviousChannels = true }
                return []
            }
            return try await loadBackgroundStateChannels(with: Pagination(pageSize: limit, cursor: cursor))
        } else {
            let channels = try await loadBackgroundStateChannels(with: Pagination(pageSize: limit, offset: count))
            backgroundState { $0.hasLoadedAllPreviousChannels = channels.isEmpty || channels.count < limit }
            return channels
        }
    }

    /// Refreshes the channels currently loaded into the non-isolated background state.
    @discardableResult
    func refreshLoadedBackgroundStateChannels() async throws -> Set<ChannelId> {
        let (count, query) = backgroundState { ($0.channels.count, $0.query) }
        return try await channelListUpdater.refreshLoadedChannels(for: query, channelCount: count)
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

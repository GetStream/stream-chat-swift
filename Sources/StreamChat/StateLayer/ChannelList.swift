//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// An object which represents a list of `ChatChannel`s for the specified  channel query.
public class ChannelList: @unchecked Sendable {
    private let channelListUpdater: ChannelListUpdater
    private let currentUserUpdater: CurrentUserUpdater
    private let deliveryCriteriaValidator: MessageDeliveryCriteriaValidating
    private let client: ChatClient
    let observer: ChannelListState.Observer
    @MainActor private var stateBuilder: StateBuilder<ChannelListState>
    let groupKey: String?

    init(
        query: ChannelListQuery,
        dynamicFilter: (@Sendable (ChatChannel) -> Bool)?,
        client: ChatClient,
        environment: Environment = .init()
    ) {
        self.client = client
        self.groupKey = query.groupKey
        let channelListUpdater = environment.channelListUpdater(
            client.databaseContainer,
            client.apiClient
        )
        self.channelListUpdater = channelListUpdater
        currentUserUpdater = environment.currentUserUpdater(
            client.databaseContainer,
            client.apiClient
        )
        deliveryCriteriaValidator = environment.deliveryCriteriaValidator()
        let query = channelListUpdater.loadPredefinedFilter(for: query) ?? query
        let observer = ChannelListState.Observer(
            query: query,
            dynamicFilter: dynamicFilter,
            clientConfig: client.config,
            channelListUpdater: channelListUpdater,
            database: client.databaseContainer,
            eventNotificationCenter: client.eventNotificationCenter,
            channelWatcherHandler: client.channelWatcherHandler
        )
        self.observer = observer
        stateBuilder = StateBuilder {
            environment.stateBuilder(query, observer)
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
    @discardableResult public func get() async throws -> [ChatChannel] {
        let pagination = Pagination(pageSize: await state.query.pagination.pageSize)
        let channels = try await loadChannels(with: pagination)
        client.syncRepository.startTrackingChannelList(self)
        return channels
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
            let channels = group?.channels ?? []
            await markChannelsAsDeliveredIfNeeded(channels)
            return channels
        } else {
            var query = await state.query
            query.pagination = pagination
            let result = try await channelListUpdater.update(channelListQuery: query)
            if let updatedQuery = result.updatedQuery {
                await state.setQuery(updatedQuery)
            }
            await markChannelsAsDeliveredIfNeeded(result.channels)
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

    private func markChannelsAsDeliveredIfNeeded(_ channels: [ChatChannel]) async {
        guard !channels.isEmpty else { return }
        guard let currentUser = try? await client.databaseContainer.read({ try $0.currentUser?.asModel() }) else { return }

        let deliveries: [MessageDeliveryInfo] = channels.compactMap { channel in
            guard let message = channel.latestMessages.first else { return nil }
            guard deliveryCriteriaValidator.canMarkMessageAsDelivered(message, for: currentUser, in: channel) else { return nil }
            return MessageDeliveryInfo(channelId: channel.cid, messageId: message.id)
        }

        guard !deliveries.isEmpty else { return }

        currentUserUpdater.markMessagesAsDelivered(deliveries) { error in
            if let error {
                log.error("Failed to mark channels as delivered: \(error)")
            }
        }
    }
}

extension ChannelList {
    struct Environment: Sendable {
        var channelListUpdater: @Sendable (
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> ChannelListUpdater = { ChannelListUpdater(database: $0, apiClient: $1) }

        var currentUserUpdater: @Sendable (
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> CurrentUserUpdater = { CurrentUserUpdater(database: $0, apiClient: $1) }

        var deliveryCriteriaValidator: @Sendable () -> MessageDeliveryCriteriaValidating = {
            MessageDeliveryCriteriaValidator()
        }

        var stateBuilder: @Sendable @MainActor (
            _ query: ChannelListQuery,
            _ observer: ChannelListState.Observer
        ) -> ChannelListState = { @MainActor in
            ChannelListState(query: $0, observer: $1)
        }
    }
}

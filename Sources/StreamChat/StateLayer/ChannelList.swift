//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// An object which represents a list of `ChatChannel`.
@available(iOS 13.0, *)
public class ChannelList {
    private let channelListUpdater: ChannelListUpdater
    private let stateBuilder: StateBuilder<ChannelListState>
    
    init(
        initialChannels: [ChatChannel],
        query: ChannelListQuery,
        dynamicFilter: ((ChatChannel) -> Bool)?,
        channelListUpdater: ChannelListUpdater,
        client: ChatClient,
        environment: Environment = .init()
    ) {
        self.channelListUpdater = channelListUpdater
        self.query = query
        stateBuilder = StateBuilder {
            environment.stateBuilder(
                initialChannels,
                query,
                dynamicFilter,
                client.config,
                channelListUpdater,
                client.databaseContainer,
                client.eventNotificationCenter
            )
        }
    }
    
    /// The query specifying and filtering the list of channels.
    public let query: ChannelListQuery
    
    /// An observable object representing the current state of the channel list.
    @MainActor public lazy var state: ChannelListState = stateBuilder.build()
    
    // MARK: - Channel List Pagination
    
    /// Loads channels for the specified pagination parameters and updates ``ChannelListState/channels``.
    ///
    /// - Parameter pagination: The pagination configuration which includes limit and cursor.
    ///
    /// - Throws: An error while communicating with the Stream API.
    /// - Returns: An array of channels for the pagination.
    @discardableResult public func loadChannels(with pagination: Pagination) async throws -> [ChatChannel] {
        guard pagination.pageSize > 0 else { return [] }
        return try await channelListUpdater.loadChannels(query: query, pagination: pagination)
    }
    
    /// Loads more channels and updates ``ChannelListState/channels``.
    ///
    /// - Parameter limit: The limit for the page size. The default limit is 20.
    ///
    /// - Throws: An error while communicating with the Stream API.
    /// - Returns: An array of loaded channels.
    @discardableResult public func loadNextChannels(limit: Int? = nil) async throws -> [ChatChannel] {
        let limit = limit ?? query.pagination.pageSize
        let count = await state.channels.count
        return try await channelListUpdater.loadNextChannels(query: query, limit: limit, loadedChannelsCount: count)
    }
}

@available(iOS 13.0, *)
extension ChannelList {
    struct Environment {
        var stateBuilder: @MainActor(
            _ initialChannels: [ChatChannel],
            _ query: ChannelListQuery,
            _ dynamicFilter: ((ChatChannel) -> Bool)?,
            _ clientConfig: ChatClientConfig,
            _ channelListUpdater: ChannelListUpdater,
            _ database: DatabaseContainer,
            _ eventNotificationCenter: EventNotificationCenter
        ) -> ChannelListState = { @MainActor in
            ChannelListState(
                initialChannels: $0,
                query: $1,
                dynamicFilter: $2,
                clientConfig: $3,
                channelListUpdater: $4,
                database: $5,
                eventNotificationCenter: $6
            )
        }
    }
}

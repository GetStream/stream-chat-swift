//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// An object which represents a list of `ChatChannel`.
@available(iOS 13.0, *)
public class ChannelList {
    private let channelListUpdater: ChannelListUpdater
    private let stateBuilder: StateBuilder<ChannelListState>
    let query: ChannelListQuery
    
    init(
        query: ChannelListQuery,
        dynamicFilter: ((ChatChannel) -> Bool)?,
        client: ChatClient,
        environment: Environment = .init()
    ) {
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
                client.eventNotificationCenter
            )
        }
    }
    
    /// An observable object representing the current state of the channel list.
    @MainActor public lazy var state: ChannelListState = stateBuilder.build()
    
    // MARK: - Channel List Pagination
    
    /// Loads channels for the specified pagination parameters and updates ``ChannelListState/channels``.
    ///
    /// - Important: If pagination offset is 0 and cursor is nil, the list of loaded channels is reset.
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
        var channelListUpdater: (
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> ChannelListUpdater = ChannelListUpdater.init
        
        var stateBuilder: @MainActor(
            _ query: ChannelListQuery,
            _ dynamicFilter: ((ChatChannel) -> Bool)?,
            _ clientConfig: ChatClientConfig,
            _ channelListUpdater: ChannelListUpdater,
            _ database: DatabaseContainer,
            _ eventNotificationCenter: EventNotificationCenter
        ) -> ChannelListState = { @MainActor in
            ChannelListState(
                query: $0,
                dynamicFilter: $1,
                clientConfig: $2,
                channelListUpdater: $3,
                database: $4,
                eventNotificationCenter: $5
            )
        }
    }
}

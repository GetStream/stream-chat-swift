//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// An object which represents a list of `ChatChannel`.
@available(iOS 13.0, *)
public struct ChatList {
    /// The query specifying and filtering the list of channels.
    public let query: ChannelListQuery
    
    private let channelListQueryLinkingCoordinator: ChannelListQueryLinkingCoordinator
    private let channelListUpdater: ChannelListUpdater
    private let paginatedChannelsLoader: PaginatedChannelsLoader
    
    init(channels: [ChatChannel], query: ChannelListQuery, dynamicFilter: ((ChatChannel) -> Bool)?, channelListUpdater: ChannelListUpdater, client: ChatClient, environment: Environment = .init()) {
        self.channelListUpdater = channelListUpdater
        self.query = query
        let state = environment.stateBuilder(
            channels,
            query,
            client.config,
            client.databaseContainer
        )
        channelListQueryLinkingCoordinator = environment.channelListQueryLinkingCoordinatorBuilder(
            state,
            query,
            dynamicFilter,
            channelListUpdater,
            client.eventsController(),
            client.databaseContainer,
            client.config
        )
        paginatedChannelsLoader = environment.paginatedChannelsLoaderBuilder(
            query,
            client.config,
            channelListUpdater,
            client.channelRepository
        )
        self.state = state
    }
    
    /// An observable object representing the current state of the channel list.
    public let state: ChatListState
    
    // MARK: - Channel List Pagination
    
    /// Loads channels for the specified pagination parameters and updates ``ChatListState.channels``.
    ///
    /// - Parameters:
    ///   - pagination: The pagination configuration which includes limit and cursor.
    ///
    /// - Throws: An error while communicating with the Stream API.
    /// - Returns: An array of channels for the pagination.
    @discardableResult public func loadChannels(with pagination: Pagination) async throws -> [ChatChannel] {
        try await paginatedChannelsLoader.loadChannels(to: state, pagination: pagination)
    }
    
    /// Loads more channels and updates ``ChatListState.channels``.
    ///
    /// - Parameters
    ///   - limit: The limit for the page size. The default limit is 20.
    ///
    /// - Throws: An error while communicating with the Stream API.
    /// - Returns: An array of loaded channels.
    @discardableResult public func loadMoreChannels(with limit: Int? = nil) async throws -> [ChatChannel] {
        try await paginatedChannelsLoader.loadMoreChannels(to: state, limit: limit)
    }
}

@available(iOS 13.0, *)
extension ChatList {
    struct Environment {
        var channelListQueryLinkingCoordinatorBuilder: (
            _ state: ChatListState,
            _ query: ChannelListQuery,
            _ filter: ((ChatChannel) -> Bool)?,
            _ channelListUpdater: ChannelListUpdater,
            _ eventsController: EventsController,
            _ database: DatabaseContainer,
            _ clientConfig: ChatClientConfig
        ) -> ChannelListQueryLinkingCoordinator = ChannelListQueryLinkingCoordinator.init
        
        var paginatedChannelsLoaderBuilder: (
            _ query: ChannelListQuery,
            _ chatClientConfig: ChatClientConfig,
            _ channelListUpdater: ChannelListUpdater,
            _ channelRepository: ChannelRepository
        ) -> PaginatedChannelsLoader = PaginatedChannelsLoader.init
        
        var stateBuilder: (
            _ channels: [ChatChannel],
            _ query: ChannelListQuery,
            _ clientConfig: ChatClientConfig,
            _ database: DatabaseContainer
        ) -> ChatListState = ChatListState.init
    }
}

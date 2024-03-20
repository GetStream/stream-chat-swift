//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

// MARK: - Factory Methods for Currently Logged In User

@available(iOS 13.0, *)
extension ChatClient {
    /// Creates an instance of ``ConnectedUser`` which represents the logged-in user state and its actions.
    ///
    /// - Throws: An error if no user is currently logged-in.
    func makeConnectedUser() async throws -> ConnectedUser {
        let user = try await databaseContainer.backgroundRead { try CurrentUserDTO.load(context: $0) }
        return ConnectedUser(user: user, client: self)
    }
}

// MARK: - Factory Methods for Creating Channel Lists

@available(iOS 13.0, *)
extension ChatClient {
    /// Creates an instance of ``ChannelList`` which represents an array of channels matching to the specified ``ChannelListQuery``.
    ///
    /// Loaded channels are stored in ``ChannelListState/channels``. Use pagination methods in ``ChannelList`` for loading more matching channels to the observable state.
    /// Refer to [querying channels in Stream documentation](https://getstream.io/chat/docs/ios-swift/query_channels/?language=swift) for additional details.
    ///
    /// - Note: Only channels that the user can read are returned, therefore, make sure that the query uses a filter that includes such logic. It is recommended to include a members filter which includes the currently logged in user (e.g. `.containMembers(userIds: ["thierry"])`).
    ///
    /// - Parameters:
    ///   - query: The query specifies which channels are part of the list and how channels are sorted.
    ///   - dynamicFilter: A filter block for filtering by channel's extra data fields or as a manual filter when ``ChatClientConfig/isChannelAutomaticFilteringEnabled`` is false ([read more](https://getstream.io/chat/docs/sdk/ios/client/controllers/channels/)).
    ///
    /// - Throws: An error while communicating with the Stream API.
    /// - Returns: An instance of ``ChannelList`` which represents actions and the current state of the list.
    public func makeChannelList(with query: ChannelListQuery, dynamicFilter: ((ChatChannel) -> Bool)? = nil) async throws -> ChannelList {
        let channels = try await channelListUpdater.update(channelListQuery: query)
        return ChannelList(channels: channels, query: query, dynamicFilter: dynamicFilter, channelListUpdater: channelListUpdater, client: self)
    }
}

// MARK: - Factory Methods for Creating User Lists

@available(iOS 13.0, *)
extension ChatClient {
    /// Creates an instance of ``UserList`` which represents an array of users matching to the specified ``UserListQuery``.
    ///
    /// Loaded users are stored in ``UserListState/users``. Use pagination methods in ``UserList`` for loading more matching users to the observable state.
    /// Refer to [querying users in Stream documentation](https://getstream.io/chat/docs/ios-swift/query_users/?language=swift) for additional details.
    ///
    /// - Parameter query: The query specifies which users are part of the list and how users are sorted.
    ///
    /// - Throws: An error while communicating with the Stream API.
    /// - Returns: An instance of ``UserList`` which represents actions and the current state of the list.
    public func makeUserList(with query: UserListQuery) async throws -> UserList {
        let userListUpdater = UserListUpdater(database: databaseContainer, apiClient: apiClient)
        let users = try await userListUpdater.update(userListQuery: query)
        return UserList(users: users, query: query, userListUpdater: userListUpdater, client: self)
    }
}

// MARK: - Factory Methods for Creating Chats

@available(iOS 13.0, *)
extension ChatClient {
    // MARK: - Find Locally Available Chat by ID
    
    /// An instance of `Chat` which represents a channel with the specified id.
    ///
    /// - Note: Provides a quick lookup of a chat. It is caller's responsibility to call ``Chat/watch()`` for receiving the most recent state from the server.
    ///
    /// - Parameters:
    ///   - cid: The id of the channel.
    ///   - channelListQuery: The channel list query the channel belongs to.
    ///   - messageOrdering: Describes the ordering the messages are presented.
    ///   - memberSorting: The sorting order for channel members (the default sorting by created at in ascending order).
    ///
    /// - Returns: An instance of Chat representing the channel.
    ///
    public func makeChat(
        for cid: ChannelId,
        channelListQuery: ChannelListQuery? = nil,
        messageOrdering: MessageOrdering = .topToBottom,
        memberSorting: [Sorting<ChannelMemberListSortingKey>] = []
    ) -> Chat {
        let channelUpdater = makeChannelUpdater()
        let channelQuery = ChannelQuery(cid: cid)
        // TODO: Review pagination state since watch and channel updater's update are slightly different
        return Chat(
            cid: cid,
            channelQuery: channelQuery,
            channelListQuery: channelListQuery,
            messageOrdering: messageOrdering,
            memberSorting: memberSorting,
            channelUpdater: channelUpdater,
            client: self
        )
    }
    
    // MARK: - Create a Chat with a Query
    
    /// An instance of `Chat` which represents a channel with the channel query.
    ///
    /// - Note: The method syncs the state before returning the instance and starts watching for changes.
    ///
    /// - Parameters:
    ///   - channelQuery: The channel query used for looking up a channel.
    ///   - channelListQuery: The channel list query the channel belongs to.
    ///   - messageOrdering: Describes the ordering the messages are presented.
    ///   - memberSorting: The sorting order for channel members (the default sorting by created at in ascending order).
    ///
    /// - Throws: An error while communicating with the Stream API.
    /// - Returns: An instance of `Chat` representing the channel.
    public func makeChat(
        with channelQuery: ChannelQuery,
        channelListQuery: ChannelListQuery? = nil,
        messageOrdering: MessageOrdering = .topToBottom,
        memberSorting: [Sorting<ChannelMemberListSortingKey>] = []
    ) async throws -> Chat {
        // Always update although the cid could be provided through channel query
        let channelUpdater = makeChannelUpdater()
        let response = try await channelUpdater.update(channelQuery: channelQuery, isInRecoveryMode: false)
        let cid = response.channel.cid
        return Chat(
            cid: cid,
            channelQuery: channelQuery,
            channelListQuery: channelListQuery,
            messageOrdering: messageOrdering,
            memberSorting: memberSorting,
            channelUpdater: channelUpdater,
            client: self
        )
    }
    
    // MARK: - Topic Based Chat
    
    /// An instance of `Chat` which represents a channel with specified configuration.
    ///
    /// Creates a new channel or returns an existing channel by modifying its configuration if needed.
    ///
    /// - Note: The method syncs the state before returning the instance and starts watching for changes.
    ///
    /// - Parameters:
    ///   - cid: The id of the channel.
    ///   - name: The name of the channel.
    ///   - imageURL: The channel avatar URL.
    ///   - team: The team for the channel.
    ///   - members: A list of members for the channel.
    ///   - isCurrentUserMember: If `true`, the current user is added as member.
    ///   - invites: A list of users who will get invites.
    ///   - messageOrdering: Describes the ordering the messages are presented.
    ///   - memberSorting: The sorting order for channel members (the default sorting by created at in ascending order).
    ///   - channelListQuery: The channel list query the channel belongs to.
    ///   - extraData: Extra data for the new channel.
    ///
    /// - Throws: An error while communicating with the Stream API.
    /// - Returns: An instance of `Chat` representing the channel.
    public func makeChat(
        with cid: ChannelId,
        name: String? = nil,
        imageURL: URL? = nil,
        team: String? = nil,
        members: [UserId] = [],
        isCurrentUserMember: Bool = true,
        invites: [UserId] = [],
        messageOrdering: MessageOrdering = .topToBottom,
        memberSorting: [Sorting<ChannelMemberListSortingKey>] = [],
        channelListQuery: ChannelListQuery? = nil,
        extraData: [String: RawJSON] = [:]
    ) async throws -> Chat {
        guard let currentUserId = currentUserId else { throw ClientError.CurrentUserDoesNotExist() }
        let payload = ChannelEditDetailPayload(
            cid: cid,
            name: name,
            imageURL: imageURL,
            team: team,
            members: Set(members).union(isCurrentUserMember ? [currentUserId] : []),
            invites: Set(invites),
            extraData: extraData
        )
        let channelQuery = ChannelQuery(channelPayload: payload)
        let channelUpdater = makeChannelUpdater()
        let response = try await channelUpdater.update(channelQuery: channelQuery, isInRecoveryMode: false)
        return Chat(
            cid: response.channel.cid,
            channelQuery: channelQuery,
            channelListQuery: channelListQuery,
            messageOrdering: messageOrdering,
            memberSorting: memberSorting,
            channelUpdater: channelUpdater,
            client: self
        )
    }
    
    // MARK: - Direct Messages
    
    /// An instance of `Chat` which represents a channel with specified members.
    ///
    /// Use this for direct message channels because the channel is uniquely identified by
    /// its members. Creates a new channel or returns an existing channel by modifying its configuration if needed.
    ///
    /// - Note: The method syncs the state before returning the instance and starts watching for changes.
    ///
    /// - Parameters:
    ///   - members: An array of user ids.
    ///   - type: The type of the channel.
    ///   - isCurrentUserMember: If `true`, the current user is added as member.
    ///   - name: The name of the channel.
    ///   - imageURL: The channel avatar URL.
    ///   - team: The team for the channel.
    ///   - messageOrdering: Describes the ordering the messages are presented.
    ///   - memberSorting: The sorting order for channel members (the default sorting by created at in ascending order).
    ///   - channelListQuery: The channel list query the channel belongs to.
    ///   - extraData: Extra data for the new channel.
    ///
    /// - Throws: An error while communicating with the Stream API.
    /// - Returns: An instance of `Chat` representing the channel.
    public func makeDirectMessageChat(
        with members: [UserId],
        type: ChannelType = .messaging,
        isCurrentUserMember: Bool = true,
        name: String? = nil,
        imageURL: URL? = nil,
        team: String? = nil,
        messageOrdering: MessageOrdering = .topToBottom,
        memberSorting: [Sorting<ChannelMemberListSortingKey>] = [],
        channelListQuery: ChannelListQuery? = nil,
        extraData: [String: RawJSON]
    ) async throws -> Chat {
        guard let currentUserId = authenticationRepository.currentUserId else { throw ClientError.CurrentUserDoesNotExist() }
        guard !members.isEmpty else { throw ClientError.ChannelEmptyMembers() }
        let payload = ChannelEditDetailPayload(
            type: type,
            name: name,
            imageURL: imageURL,
            team: team,
            members: Set(members).union(isCurrentUserMember ? [currentUserId] : []),
            invites: [],
            extraData: extraData
        )
        let channelQuery = ChannelQuery(channelPayload: payload)
        let channelUpdater = makeChannelUpdater()
        let response = try await channelUpdater.update(channelQuery: channelQuery, isInRecoveryMode: false)
        return Chat(
            cid: response.channel.cid,
            channelQuery: channelQuery,
            channelListQuery: channelListQuery,
            messageOrdering: messageOrdering,
            memberSorting: memberSorting,
            channelUpdater: channelUpdater,
            client: self
        )
    }
    
    private func makeChannelUpdater() -> ChannelUpdater {
        ChannelUpdater(
            channelRepository: channelRepository,
            callRepository: callRepository,
            messageRepository: messageRepository,
            paginationStateHandler: makeMessagesPaginationStateHandler(),
            database: databaseContainer,
            apiClient: apiClient
        )
    }
}

// MARK: - Factory Methods for Creating Channel Member Lists

@available(iOS 13.0, *)
extension ChatClient {
    /// Creates an instance of ``MemberList`` which represents an array of channel members matching to the specified ``ChannelMemberListQuery``.
    ///
    /// - Note: Call the paginated load methods for loading the list of channel members.
    ///
    /// - Parameter query: The query which defines a channel, filter and sorting options.
    ///
    /// - Returns: An instance of ``MemberList`` which represents actions and the current state of the list.
    public func makeMemberList(with query: ChannelMemberListQuery) -> MemberList {
        MemberList(query: query, client: self)
    }
}

// MARK: - Factory Methods for Searching Messages

@available(iOS 13.0, *)
extension ChatClient {
    /// Creates an instance of ``MessageSearch`` which represents an array of messages matching to the specified ``MessageSearchQuery``.
    ///
    /// Use ``MessageSearch`` as a data source for UIs representing message search.
    ///
    /// - Returns: An instance of ``MessageSearch`` which represents search actions and the search state.
    public func makeMessageSearch() -> MessageSearch {
        MessageSearch(client: self)
    }
}

// MARK: - Factory Methods for Searching User

@available(iOS 13.0, *)
extension ChatClient {
    /// Creates an instance of ``UserSearch`` which represents an array of users matching to the specified ``UserListQuery``.
    ///
    /// Use ``UserSearch`` as a data source for user search UIs.
    ///
    /// - Returns: An instance of ``UserSearch`` which represents search actions and the search state.
    public func makeUserSearch() -> UserSearch {
        UserSearch(client: self)
    }
}

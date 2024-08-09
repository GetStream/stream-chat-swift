//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

// MARK: - Factory Methods for Currently Logged In User

extension ChatClient {
    /// Creates an instance of ``ConnectedUser`` which represents the logged-in user state and its actions.
    ///
    /// - Throws: An error if no user is currently logged-in.
    @MainActor public func makeConnectedUser() throws -> ConnectedUser {
        let user = try CurrentUserDTO.load(context: databaseContainer.viewContext)
        return ConnectedUser(user: user, client: self)
    }
}

// MARK: - Factory Methods for Creating Channel Lists

extension ChatClient {
    /// Creates an instance of ``ChannelList`` which represents an array of channels matching to the specified ``ChannelListQuery``.
    ///
    /// Loaded channels are stored in ``ChannelListState/channels``. Use pagination methods in ``ChannelList`` for refreshing or loading more matching channels to the observable state.
    /// Refer to [querying channels in Stream documentation](https://getstream.io/chat/docs/ios-swift/query_channels/?language=swift) for additional details.
    ///
    /// - Note: Only channels that the user can read are returned, therefore, make sure that the query uses a filter that includes such logic. It is recommended to include a members filter which includes the currently logged in user (e.g. `.containMembers(userIds: ["thierry"])`).
    ///
    /// - Parameters:
    ///   - query: The query specifies which channels are part of the list and how channels are sorted.
    ///   - dynamicFilter: A filter block for filtering by channel's extra data fields or as a manual filter when ``ChatClientConfig/isChannelAutomaticFilteringEnabled`` is false ([read more](https://getstream.io/chat/docs/sdk/ios/client/controllers/channels/)).
    ///
    /// - Returns: An instance of ``ChannelList`` which represents actions and the state of the list.
    public func makeChannelList(
        with query: ChannelListQuery,
        dynamicFilter: ((ChatChannel) -> Bool)? = nil
    ) -> ChannelList {
        ChannelList(query: query, dynamicFilter: dynamicFilter, client: self)
    }
}

// MARK: - Factory Methods for Creating Chats

extension ChatClient {
    // MARK: - Create a Chat with Channel ID
    
    /// An instance of `Chat` which represents a channel with the specified channel id.
    ///
    /// - Note: It is caller's responsibility to call ``Chat/get(watch:)`` for receiving the most recent state from the server.
    ///
    /// - Parameters:
    ///   - cid: The id of the channel.
    ///   - messageOrdering: Describes the ordering the messages are presented.
    ///   - memberSorting: The sorting order for channel members (the default sorting is by created at in ascending order).
    ///
    /// - Returns: An instance of Chat representing the channel.
    public func makeChat(
        for cid: ChannelId,
        messageOrdering: MessageOrdering = .topToBottom,
        memberSorting: [Sorting<ChannelMemberListSortingKey>] = []
    ) -> Chat {
        makeChat(
            with: ChannelQuery(cid: cid),
            messageOrdering: messageOrdering,
            memberSorting: memberSorting
        )
    }
    
    // MARK: - Create a Chat with a Channel Query
    
    /// An instance of `Chat` which represents a channel with the channel query.
    ///
    /// - Note: It is caller's responsibility to call ``Chat/get(watch:)`` for receiving the most recent state from the server.
    ///
    /// - Parameters:
    ///   - channelQuery: The channel query used for looking up a channel.
    ///   - messageOrdering: Describes the ordering the messages are presented.
    ///   - memberSorting: The sorting order for channel members (the default sorting is by created at in ascending order).
    ///
    /// - Returns: An instance of `Chat` representing the channel.
    public func makeChat(
        with channelQuery: ChannelQuery,
        messageOrdering: MessageOrdering = .topToBottom,
        memberSorting: [Sorting<ChannelMemberListSortingKey>] = []
    ) -> Chat {
        Chat(
            channelQuery: channelQuery,
            messageOrdering: messageOrdering,
            memberSorting: memberSorting,
            client: self
        )
    }
    
    // MARK: - Create a Chat with Specified Configuration
    
    /// An instance of `Chat` which represents a channel with specified configuration.
    ///
    /// Creates a new channel or returns an existing channel by modifying its configuration if needed.
    ///
    /// - Note: It is caller's responsibility to call ``Chat/get(watch:)`` for receiving the most recent state from the server.
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
    ///   - memberSorting: The sorting order for channel members (the default sorting is by created at in ascending order).
    ///   - channelListQuery: The channel list query the channel belongs to.
    ///   - extraData: Extra data for the new channel.
    ///
    /// - Throws: An error if no user is currently logged-in.
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
    ) throws -> Chat {
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
        return makeChat(
            with: channelQuery,
            messageOrdering: messageOrdering,
            memberSorting: memberSorting
        )
    }
    
    // MARK: - Create a Chat for Direct Messages
    
    /// An instance of `Chat` which represents a channel with specified members.
    ///
    /// Use this for direct message channels because the channel is uniquely identified by
    /// its members. Creates a new channel or returns an existing channel by modifying its configuration if needed.
    ///
    /// - Note: It is caller's responsibility to call ``Chat/get(watch:)`` for receiving the most recent state from the server.
    ///
    /// - Parameters:
    ///   - members: An array of user ids.
    ///   - type: The type of the channel.
    ///   - isCurrentUserMember: If `true`, the current user is added as member.
    ///   - name: The name of the channel.
    ///   - imageURL: The channel avatar URL.
    ///   - team: The team for the channel.
    ///   - messageOrdering: Describes the ordering the messages are presented.
    ///   - memberSorting: The sorting order for channel members (the default sorting is by created at in ascending order).
    ///   - channelListQuery: The channel list query the channel belongs to.
    ///   - extraData: Extra data for the new channel.
    ///
    /// - Throws: An error if no user is currently logged-in.
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
    ) throws -> Chat {
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
        return makeChat(
            with: channelQuery,
            messageOrdering: messageOrdering,
            memberSorting: memberSorting
        )
    }
}

// MARK: - Factory Methods for Creating Channel Member Lists

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

// MARK: - Factory Methods for Creating Message Reaction Lists

extension ChatClient {
    /// Creates an instance of ``ReactionList`` which represents an array of message reactions matching to the specified ``ReactionListQuery``.
    ///
    /// - Note: Call the paginated load methods for loading the list of message reactions.
    ///
    /// - Parameter query: The query which defines a message and filter.
    ///
    /// - Returns: An instance of ``ReactionList`` which represents actions and the current state of the list.
    public func makeReactionList(with query: ReactionListQuery) -> ReactionList {
        ReactionList(query: query, client: self)
    }
}

// MARK: - Factory Methods for Creating User Lists

extension ChatClient {
    /// Creates an instance of ``UserList`` which represents an array of users matching to the specified ``UserListQuery``.
    ///
    /// Loaded users are stored in ``UserListState/users``. Use pagination methods in ``UserList`` for refreshing or loading more matching users to the observable state.
    /// Refer to [querying users in Stream documentation](https://getstream.io/chat/docs/ios-swift/query_users/?language=swift) for additional details.
    ///
    /// - Parameter query: The query specifies which users are part of the list and how users are sorted.
    ///
    /// - Returns: An instance of ``UserList`` which represents actions and the state of the list.
    public func makeUserList(with query: UserListQuery) -> UserList {
        UserList(query: query, client: self)
    }
}

// MARK: - Factory Methods for Searching Messages

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

// MARK: - Factory Methods for Searching Users

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

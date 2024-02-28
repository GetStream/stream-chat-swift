//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

// MARK: - Factory methods to create the chat.

@available(iOS 13.0, *)
extension ChatClient {
    // MARK: - Find Locally Available Chat by ID
    
    /// An instance of `Chat` which represents a channel with the specified id.
    ///
    /// - Note: Provides a quick lookup of a channel. Use if for channels which are available locally.
    ///
    /// - Parameters:
    ///   - cid: The id of the channel.
    ///   - channelListQuery: The channel list query the channel belongs to.
    ///   - messageOrdering: Describes the ordering the messages are presented.
    /// - Returns: An instance of Chat representing the channel.
    ///
    
    // TODO: we should rename: makeXXX
    public func chat(
        for cid: ChannelId,
        channelListQuery: ChannelListQuery? = nil,
        messageOrdering: MessageOrdering = .topToBottom
    ) -> Chat {
        let channelUpdater = makeChannelUpdater()
        let channelQuery = ChannelQuery(cid: cid)
        Task {
            try await channelUpdater.update(channelQuery: channelQuery, isInRecoveryMode: false)
        }
        return Chat(
            cid: cid,
            channelQuery: channelQuery,
            channelListQuery: channelListQuery,
            messageOrdering: messageOrdering,
            channelUpdater: channelUpdater,
            client: self
        )
    }
    
    // MARK: - Create a Chat with a Query
    
    /// An instance of `Chat` which represents a channel with the channel query.
    ///
    /// - Note: The method syncs the state before returning the instance.
    ///
    /// - Parameters:
    ///   - channelQuery: The channel query used for looking up a channel.
    ///   - channelListQuery: The channel list query the channel belongs to.
    ///   - messageOrdering: Describes the ordering the messages are presented.
    ///
    /// - Throws: An error while communicating with the Stream API.
    /// - Returns: An instance of `Chat` representing the channel.
    public func chat(
        with channelQuery: ChannelQuery,
        channelListQuery: ChannelListQuery? = nil,
        messageOrdering: MessageOrdering = .topToBottom
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
            channelUpdater: channelUpdater,
            client: self
        )
    }
    
    // MARK: - Topic Based Chat
    
    /// An instance of `Chat` which represents a channel with specified configuration.
    ///
    /// Creates a new channel or returns an existing channel by modifying its configuration if needed.
    ///
    /// - Note: The method syncs the state before returning the instance.
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
    ///   - channelListQuery: The channel list query the channel belongs to.
    ///   - extraData: Extra data for the new channel.
    ///
    /// - Throws: An error while communicating with the Stream API.
    /// - Returns: An instance of `Chat` representing the channel.
    public func chat(
        with cid: ChannelId,
        name: String? = nil,
        imageURL: URL? = nil,
        team: String? = nil,
        members: [UserId] = [],
        isCurrentUserMember: Bool = true,
        invites: [UserId] = [],
        messageOrdering: MessageOrdering = .topToBottom,
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
    /// - Note: The method syncs the state before returning the instance.
    ///
    /// - Parameters:
    ///   - members: An array of user ids.
    ///   - type: The type of the channel.
    ///   - isCurrentUserMember: If `true`, the current user is added as member.
    ///   - name: The name of the channel.
    ///   - imageURL: The channel avatar URL.
    ///   - team: The team for the channel.
    ///   - messageOrdering: Describes the ordering the messages are presented.
    ///   - channelListQuery: The channel list query the channel belongs to.
    ///   - extraData: Extra data for the new channel.
    ///
    /// - Throws: An error while communicating with the Stream API.
    /// - Returns: An instance of `Chat` representing the channel.
    public func directMessageChat(
        with members: [UserId],
        type: ChannelType = .messaging,
        isCurrentUserMember: Bool = true,
        name: String? = nil,
        imageURL: URL? = nil,
        team: String? = nil,
        messageOrdering: MessageOrdering = .topToBottom,
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
            channelUpdater: channelUpdater,
            client: self
        )
    }
    
    private func makeChannelUpdater() -> ChannelUpdater {
        ChannelUpdater(
            channelRepository: channelRepository,
            callRepository: callRepository,
            paginationStateHandler: makeMessagesPaginationStateHandler(),
            database: databaseContainer,
            apiClient: apiClient
        )
    }
}

// MARK: - Compatibility Methods

@available(iOS 13.0, *)
extension ChatChannelController {
    /// Converts the channel controller to an instance of `Chat`.
    ///
    /// - Note: This is a compatibility method for the new state layer represented by `Chat`.
    public var chat: Chat {
        if let cid = cid {
            return client.chat(for: cid)
        } else {
            fatalError("Trying to access channel controller before it was synchronized")
        }
    }
}

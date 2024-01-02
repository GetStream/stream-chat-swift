//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

// MARK: - Factory methods to create the controller.

public extension ChatClient {
    /// Creates a new `ChatChannelController` for the channel with the provided id.
    ///
    /// - Parameters:
    ///   - cid: The id of the channel this controller represents.
    ///   - channelListQuery: The channel list query this controller is part of.
    ///   - messageOrdering: Describes the ordering the messages are presented.
    ///
    /// - Returns: A new instance of `ChatChannelController`.
    ///
    func channelController(
        for cid: ChannelId,
        channelListQuery: ChannelListQuery? = nil,
        messageOrdering: MessageOrdering = .topToBottom
    ) -> ChatChannelController {
        .init(
            channelQuery: .init(cid: cid),
            channelListQuery: channelListQuery,
            client: self,
            messageOrdering: messageOrdering
        )
    }

    /// Creates a new `ChatChannelController` for the channel with the provided channel query.
    ///
    /// - Parameters:
    ///   - channelQuery: The ChannelQuery this controller represents
    ///   - channelListQuery: The channel list query this controller is part of.
    ///   - messageOrdering: Describes the ordering the messages are presented.
    ///
    /// - Returns: A new instance of `ChatChannelController`.
    ///
    func channelController(
        for channelQuery: ChannelQuery,
        channelListQuery: ChannelListQuery? = nil,
        messageOrdering: MessageOrdering = .topToBottom
    ) -> ChatChannelController {
        .init(
            channelQuery: channelQuery,
            channelListQuery: channelListQuery,
            client: self,
            messageOrdering: messageOrdering
        )
    }

    /// Creates a `ChatChannelController` that will create a new channel, if the channel doesn't exist already.
    ///
    /// It's safe to call this method for already existing channels. However, if you queried the channel before and you're sure it exists locally,
    /// it can be faster and more convenient to use `channelController(for cid: ChannelId)` to create a controller for it.
    ///
    /// - Parameters:
    ///   - cid: The `ChannelId` for the new channel.
    ///   - name: The new channel name.
    ///   - imageURL: The new channel avatar URL.
    ///   - team: Team for new channel.
    ///   - members: Ds for the new channel members.
    ///   - isCurrentUserMember: If set to `true` the current user will be included into the channel. Is `true` by default.
    ///   - messageOrdering: Describes the ordering the messages are presented.
    ///   - invites: IDs for the new channel invitees.
    ///   - extraData: Extra data for the new channel.
    ///   - channelListQuery: The channel list query the channel this controller represents is part of.
    /// - Throws: `ClientError.CurrentUserDoesNotExist` if there is no currently logged-in user.
    /// - Returns: A new instance of `ChatChannelController`.
    func channelController(
        createChannelWithId cid: ChannelId,
        name: String? = nil,
        imageURL: URL? = nil,
        team: String? = nil,
        members: Set<UserId> = [],
        isCurrentUserMember: Bool = true,
        messageOrdering: MessageOrdering = .topToBottom,
        invites: Set<UserId> = [],
        extraData: [String: RawJSON] = [:],
        channelListQuery: ChannelListQuery? = nil
    ) throws -> ChatChannelController {
        guard let currentUserId = currentUserId else {
            throw ClientError.CurrentUserDoesNotExist()
        }

        let payload = ChannelEditDetailPayload(
            cid: cid,
            name: name,
            imageURL: imageURL,
            team: team,
            members: members.union(isCurrentUserMember ? [currentUserId] : []),
            invites: invites,
            extraData: extraData
        )

        return .init(
            channelQuery: .init(channelPayload: payload),
            channelListQuery: channelListQuery,
            client: self,
            isChannelAlreadyCreated: false,
            messageOrdering: messageOrdering
        )
    }

    /// Creates a `ChatChannelController` that will create a new channel with the provided members without having to specify
    /// the channel id explicitly. This is great for direct message channels because the channel should be uniquely identified by
    /// its members. If the channel for these members already exist, it will be reused.
    ///
    /// It's safe to call this method for already existing channels. However, if you queried the channel before and you're sure it exists locally,
    /// it can be faster and more convenient to use `channelController(for cid: ChannelId)` to create a controller for it.
    ///
    /// - Parameters:
    ///   - members: Members for the new channel. Must not be empty.
    ///   - type: The type of the channel.
    ///   - isCurrentUserMember: If set to `true` the current user will be included into the channel. Is `true` by default.
    ///   - messageOrdering: Describes the ordering the messages are presented.
    ///   - name: The new channel name.
    ///   - imageURL: The new channel avatar URL.
    ///   - team: Team for the new channel.
    ///   - extraData: Extra data for the new channel.
    ///   - channelListQuery: The channel list query the channel this controller represents is part of.
    ///
    /// - Throws:
    ///     - `ClientError.ChannelEmptyMembers` if `members` is empty.
    ///     - `ClientError.CurrentUserDoesNotExist` if there is no currently logged-in user.
    /// - Returns: A new instance of `ChatChannelController`.
    func channelController(
        createDirectMessageChannelWith members: Set<UserId>,
        type: ChannelType = .messaging,
        isCurrentUserMember: Bool = true,
        messageOrdering: MessageOrdering = .topToBottom,
        name: String? = nil,
        imageURL: URL? = nil,
        team: String? = nil,
        extraData: [String: RawJSON],
        channelListQuery: ChannelListQuery? = nil
    ) throws -> ChatChannelController {
        guard let currentUserId = currentUserId else { throw ClientError.CurrentUserDoesNotExist() }
        guard !members.isEmpty else { throw ClientError.ChannelEmptyMembers() }

        let payload = ChannelEditDetailPayload(
            type: type,
            name: name,
            imageURL: imageURL,
            team: team,
            members: members.union(isCurrentUserMember ? [currentUserId] : []),
            invites: [],
            extraData: extraData
        )
        return .init(
            channelQuery: .init(channelPayload: payload),
            channelListQuery: channelListQuery,
            client: self,
            isChannelAlreadyCreated: false,
            messageOrdering: messageOrdering
        )
    }
}

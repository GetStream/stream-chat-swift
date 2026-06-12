//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Triggered when a new message is sent to channel.
public final class MessageNewEvent: ChannelSpecificEvent, HasUnreadCount, HasUnreadChannelCountsByGroup {
    /// The user who sent a message.
    public let user: ChatUser

    /// The message that was sent.
    public let message: ChatMessage

    /// The channel identifier the message was sent to.
    public var cid: ChannelId { channel.cid }

    /// The channel a message was sent to.
    public let channel: ChatChannel

    /// The event timestamp.
    public let createdAt: Date

    /// The # of channel watchers.
    public let watcherCount: Int?

    /// The unread counts.
    public let unreadCount: UnreadCount?

    /// Unread channel counts keyed by the backend-provided group identifier.
    public let unreadChannelCountsByGroup: [String: Int]?

    init(
        user: ChatUser,
        message: ChatMessage,
        channel: ChatChannel,
        createdAt: Date,
        watcherCount: Int?,
        unreadCount: UnreadCount?,
        unreadChannelCountsByGroup: [String: Int]? = nil
    ) {
        self.user = user
        self.message = message
        self.channel = channel
        self.createdAt = createdAt
        self.watcherCount = watcherCount
        self.unreadCount = unreadCount
        self.unreadChannelCountsByGroup = unreadChannelCountsByGroup
    }
}

extension MessageNewEventDTO: EventDTO {
    func toDomainEvent(session: any DatabaseSession) -> (any Event)? {
        guard let user = user, let userDTO = session.user(id: user.id) else { return nil }
        guard let cidString = cid, let channelId = try? ChannelId(cid: cidString) else { return nil }
        guard
            let messageDTO = session.message(id: message.id),
            let channelDTO = session.channel(cid: channelId),
            let currentUser = session.currentUser
        else { return nil }

        return try? MessageNewEvent(
            user: userDTO.asModel(),
            message: messageDTO.asModel(),
            channel: channelDTO.asModel(),
            createdAt: createdAt,
            watcherCount: watcherCount,
            unreadCount: UnreadCount(currentUserDTO: currentUser),
            unreadChannelCountsByGroup: currentUser.unreadChannelCountsByGroup
        )
    }
}

/// Triggered when a message is updated.
public final class MessageUpdatedEvent: ChannelSpecificEvent {
    /// The use who updated the message.
    public let user: ChatUser

    /// The channel identifier the message is sent to.
    public var cid: ChannelId { channel.cid }

    /// The channel a message is sent to.
    public let channel: ChatChannel

    /// The updated message.
    public let message: ChatMessage

    /// The event timestamp.
    public let createdAt: Date

    init(
        user: ChatUser,
        channel: ChatChannel,
        message: ChatMessage,
        createdAt: Date
    ) {
        self.user = user
        self.channel = channel
        self.message = message
        self.createdAt = createdAt
    }
}

extension MessageUpdatedEventDTO: EventDTO {
    func toDomainEvent(session: any DatabaseSession) -> (any Event)? {
        guard let user = user, let userDTO = session.user(id: user.id) else { return nil }
        guard let cidString = cid, let channelId = try? ChannelId(cid: cidString) else { return nil }
        guard
            let messageDTO = session.message(id: message.id),
            let channelDTO = session.channel(cid: channelId)
        else { return nil }

        return try? MessageUpdatedEvent(
            user: userDTO.asModel(),
            channel: channelDTO.asModel(),
            message: messageDTO.asModel(),
            createdAt: createdAt
        )
    }
}

/// Triggered when a new message is deleted.
public final class MessageDeletedEvent: ChannelSpecificEvent {
    /// The user who deleted the message.
    public let user: ChatUser?

    /// The channel identifier a message was deleted from.
    public var cid: ChannelId { channel.cid }

    /// The channel a message was deleted from.
    public let channel: ChatChannel

    /// The deleted message.
    public let message: ChatMessage

    /// The event timestamp.
    public let createdAt: Date

    /// A Boolean value indicating whether it is an hard delete or not.
    public let isHardDelete: Bool

    /// A Boolean value indicating whether the message was deleted only for the current user.
    public let deletedForMe: Bool

    init(
        user: ChatUser?,
        channel: ChatChannel,
        message: ChatMessage,
        createdAt: Date,
        isHardDelete: Bool,
        deletedForMe: Bool
    ) {
        self.user = user
        self.channel = channel
        self.message = message
        self.createdAt = createdAt
        self.isHardDelete = isHardDelete
        self.deletedForMe = deletedForMe
    }
}

extension MessageDeletedEventDTO: EventDTO {
    func toDomainEvent(session: any DatabaseSession) -> (any Event)? {
        guard let cidString = cid, let channelId = try? ChannelId(cid: cidString) else { return nil }
        guard let channelDTO = session.channel(cid: channelId) else { return nil }

        let userDTO = user.flatMap { session.user(id: $0.id) }

        // If the message is hard deleted, it is not available as DTO.
        // So we map the Payload Directly to the Model.
        let channelReads = (try? channelDTO.asModel().reads) ?? []
        let messageModel = message.asModel(
            cid: channelId,
            currentUserId: session.currentUser?.user.id,
            channelReads: channelReads
        )

        return try? MessageDeletedEvent(
            user: userDTO?.asModel(),
            channel: channelDTO.asModel(),
            message: messageModel,
            createdAt: createdAt,
            isHardDelete: hardDelete ?? false,
            deletedForMe: deletedForMe ?? false
        )
    }
}

/// `ChannelReadEvent`, this event tells that User has mark read all messages in channel.
public typealias ChannelReadEvent = MessageReadEvent

/// `ChannelReadEvent`, this event tells that User has mark read all messages in channel.
public final class MessageReadEvent: ChannelSpecificEvent {
    /// The user who read the channel.
    public let user: ChatUser

    /// The identifier of the read channel.
    public var cid: ChannelId { channel.cid }

    /// The read channel.
    public let channel: ChatChannel

    /// The thread if a thread was read.
    public let thread: ChatThread?

    /// The event timestamp.
    public let createdAt: Date

    /// The unread counts of the current user.
    public let unreadCount: UnreadCount?

    /// The team the channel belongs to.
    public let team: TeamId?

    init(
        user: ChatUser,
        channel: ChatChannel,
        thread: ChatThread?,
        createdAt: Date,
        unreadCount: UnreadCount?,
        team: TeamId? = nil
    ) {
        self.user = user
        self.channel = channel
        self.thread = thread
        self.createdAt = createdAt
        self.unreadCount = unreadCount
        self.team = team
    }
}

extension MessageReadEventDTO: EventDTO {
    func toDomainEvent(session: any DatabaseSession) -> (any Event)? {
        guard let user = user, let userDTO = session.user(id: user.id) else { return nil }
        guard let cidString = cid, let channelId = try? ChannelId(cid: cidString) else { return nil }
        guard
            let channelDTO = session.channel(cid: channelId),
            let currentUser = session.currentUser
        else { return nil }

        var threadDTO: ThreadDTO?
        if let threadId = thread?.parentMessageId {
            threadDTO = session.thread(parentMessageId: threadId, cache: nil)
        }

        return try? MessageReadEvent(
            user: userDTO.asModel(),
            channel: channelDTO.asModel(),
            thread: threadDTO?.asModel(),
            createdAt: createdAt,
            unreadCount: UnreadCount(currentUserDTO: currentUser),
            team: team
        )
    }
}

// Triggered when the current user creates a new message and is pending to be sent.
public final class NewMessagePendingEvent: ChannelSpecificEvent {
    public let message: ChatMessage
    public let cid: ChannelId

    init(message: ChatMessage, cid: ChannelId) {
        self.message = message
        self.cid = cid
    }
}

// Triggered when a message failed being sent.
public final class NewMessageErrorEvent: ChannelSpecificEvent {
    public let messageId: MessageId
    public let cid: ChannelId
    public let error: Error

    init(messageId: MessageId, cid: ChannelId, error: Error) {
        self.messageId = messageId
        self.cid = cid
        self.error = error
    }
}

/// Triggered when a message is delivered to a user.
public final class MessageDeliveredEvent: ChannelSpecificEvent {
    /// The user who received the delivered message.
    public let user: ChatUser

    /// The channel identifier the message was delivered to.
    public var cid: ChannelId { channel.cid }

    /// The channel the message was delivered to.
    public let channel: ChatChannel

    /// The event timestamp.
    public let createdAt: Date

    /// The ID of the last delivered message.
    public let lastDeliveredMessageId: MessageId

    /// The timestamp when the message was delivered.
    public let lastDeliveredAt: Date

    init(
        user: ChatUser,
        channel: ChatChannel,
        createdAt: Date,
        lastDeliveredMessageId: MessageId,
        lastDeliveredAt: Date
    ) {
        self.user = user
        self.channel = channel
        self.createdAt = createdAt
        self.lastDeliveredMessageId = lastDeliveredMessageId
        self.lastDeliveredAt = lastDeliveredAt
    }
}

extension MessageDeliveredEventDTO: EventDTO {
    func toDomainEvent(session: any DatabaseSession) -> (any Event)? {
        guard let user = user, let userDTO = session.user(id: user.id) else { return nil }
        guard let cidString = cid, let channelId = try? ChannelId(cid: cidString) else { return nil }
        guard let channelDTO = session.channel(cid: channelId) else { return nil }
        guard let lastDeliveredMessageId = lastDeliveredMessageId else { return nil }
        guard let lastDeliveredAt = lastDeliveredAt else { return nil }

        return try? MessageDeliveredEvent(
            user: userDTO.asModel(),
            channel: channelDTO.asModel(),
            createdAt: createdAt,
            lastDeliveredMessageId: lastDeliveredMessageId,
            lastDeliveredAt: lastDeliveredAt
        )
    }
}

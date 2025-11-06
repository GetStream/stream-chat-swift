//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// Triggered when a new message is sent to channel.
final public class MessageNewEvent: ChannelSpecificEvent, HasUnreadCount {
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

    init(
        user: ChatUser,
        message: ChatMessage,
        channel: ChatChannel,
        createdAt: Date,
        watcherCount: Int?,
        unreadCount: UnreadCount?
    ) {
        self.user = user
        self.message = message
        self.channel = channel
        self.createdAt = createdAt
        self.watcherCount = watcherCount
        self.unreadCount = unreadCount
    }
}

final class MessageNewEventDTO: EventDTO {
    let user: UserPayload
    let cid: ChannelId
    let message: MessagePayload
    let createdAt: Date
    let watcherCount: Int?
    let unreadCount: UnreadCountPayload?
    let payload: EventPayload

    init(from response: EventPayload) throws {
        user = try response.value(at: \.user)
        cid = try response.value(at: \.cid)
        message = try response.value(at: \.message)
        createdAt = try response.value(at: \.createdAt)
        watcherCount = try? response.value(at: \.watcherCount)
        unreadCount = try? response.value(at: \.unreadCount)
        payload = response
    }

    func toDomainEvent(session: DatabaseSession) -> Event? {
        guard
            let userDTO = session.user(id: user.id),
            let messageDTO = session.message(id: message.id),
            let channelDTO = session.channel(cid: cid),
            let currentUser = session.currentUser
        else { return nil }

        return try? MessageNewEvent(
            user: userDTO.asModel(),
            message: messageDTO.asModel(),
            channel: channelDTO.asModel(),
            createdAt: createdAt,
            watcherCount: watcherCount,
            unreadCount: UnreadCount(currentUserDTO: currentUser)
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

final class MessageUpdatedEventDTO: EventDTO {
    let user: UserPayload
    let cid: ChannelId
    let message: MessagePayload
    let createdAt: Date
    let payload: EventPayload

    init(from response: EventPayload) throws {
        user = try response.value(at: \.user)
        cid = try response.value(at: \.cid)
        message = try response.value(at: \.message)
        createdAt = try response.value(at: \.createdAt)
        payload = response
    }

    func toDomainEvent(session: DatabaseSession) -> Event? {
        guard
            let userDTO = session.user(id: user.id),
            let messageDTO = session.message(id: message.id),
            let channelDTO = session.channel(cid: cid)
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

final class MessageDeletedEventDTO: EventDTO {
    let user: UserPayload?
    let cid: ChannelId
    let message: MessagePayload
    let createdAt: Date
    let payload: EventPayload
    let hardDelete: Bool
    let deletedForMe: Bool?

    init(from response: EventPayload) throws {
        user = try? response.value(at: \.user)
        cid = try response.value(at: \.cid)
        message = try response.value(at: \.message)
        createdAt = try response.value(at: \.createdAt)
        payload = response
        hardDelete = response.hardDelete
        deletedForMe = response.deletedForMe
    }

    func toDomainEvent(session: DatabaseSession) -> Event? {
        guard let channelDTO = session.channel(cid: cid) else {
            return nil
        }

        let userDTO = user.flatMap { session.user(id: $0.id) }

        // If the message is hard deleted, it is not available as DTO.
        // So we map the Payload Directly to the Model.
        let channelReads = (try? channelDTO.asModel().reads) ?? []
        let message = message.asModel(
            cid: cid,
            currentUserId: session.currentUser?.user.id,
            channelReads: channelReads
        )

        return try? MessageDeletedEvent(
            user: userDTO?.asModel(),
            channel: channelDTO.asModel(),
            message: message,
            createdAt: createdAt,
            isHardDelete: hardDelete,
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

    init(
        user: ChatUser,
        channel: ChatChannel,
        thread: ChatThread?,
        createdAt: Date,
        unreadCount: UnreadCount?
    ) {
        self.user = user
        self.channel = channel
        self.thread = thread
        self.createdAt = createdAt
        self.unreadCount = unreadCount
    }
}

final class MessageReadEventDTO: EventDTO {
    let user: UserPayload
    let cid: ChannelId
    let createdAt: Date
    let unreadCount: UnreadCountPayload?
    let payload: EventPayload

    init(from response: EventPayload) throws {
        user = try response.value(at: \.user)
        cid = try response.value(at: \.cid)
        createdAt = try response.value(at: \.createdAt)
        unreadCount = try? response.value(at: \.unreadCount)
        payload = response
    }

    func toDomainEvent(session: DatabaseSession) -> Event? {
        guard
            let userDTO = session.user(id: user.id),
            let channelDTO = session.channel(cid: cid),
            let currentUser = session.currentUser
        else { return nil }

        var threadDTO: ThreadDTO?
        if let threadId = payload.threadDetails?.value?.parentMessageId {
            threadDTO = session.thread(parentMessageId: threadId, cache: nil)
        }

        return try? MessageReadEvent(
            user: userDTO.asModel(),
            channel: channelDTO.asModel(),
            thread: threadDTO?.asModel(),
            createdAt: createdAt,
            unreadCount: UnreadCount(currentUserDTO: currentUser)
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

final class MessageDeliveredEventDTO: EventDTO {
    let user: UserPayload
    let cid: ChannelId
    let createdAt: Date
    let lastDeliveredMessageId: MessageId
    let lastDeliveredAt: Date
    let payload: EventPayload

    init(from response: EventPayload) throws {
        user = try response.value(at: \.user)
        cid = try response.value(at: \.cid)
        createdAt = try response.value(at: \.createdAt)
        lastDeliveredMessageId = try response.value(at: \.lastDeliveredMessageId)
        lastDeliveredAt = try response.value(at: \.lastDeliveredAt)
        payload = response
    }

    func toDomainEvent(session: DatabaseSession) -> Event? {
        guard
            let userDTO = session.user(id: user.id),
            let channelDTO = session.channel(cid: cid)
        else { return nil }

        return try? MessageDeliveredEvent(
            user: userDTO.asModel(),
            channel: channelDTO.asModel(),
            createdAt: createdAt,
            lastDeliveredMessageId: lastDeliveredMessageId,
            lastDeliveredAt: lastDeliveredAt
        )
    }
}

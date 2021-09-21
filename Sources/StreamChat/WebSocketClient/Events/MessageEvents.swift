//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// Triggered when a new message is sent to channel.
public struct MessageNewEvent: ChannelSpecificEvent {
    /// The user who sent a message.
    public let user: ChatUser
    
    /// The message that was sent.
    public let message: ChatMessage
    
    /// The channel identifier the message was sent to.
    public let cid: ChannelId
    
    /// The event timestamp.
    public let createdAt: Date
    
    /// The # of channel watchers.
    public let watcherCount: Int?
    
    /// The unread counts.
    public let unreadCount: UnreadCount?
}

struct MessageNewEventDTO: EventWithPayload {
    let user: UserPayload
    let cid: ChannelId
    let message: MessagePayload
    let createdAt: Date
    let watcherCount: Int?
    let unreadCount: UnreadCount?
    let payload: Any
    
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
            let messageDTO = session.message(id: message.id)
        else { return nil }
        
        return MessageNewEvent(
            user: userDTO.asModel(),
            message: messageDTO.asModel(),
            cid: cid,
            createdAt: createdAt,
            watcherCount: watcherCount,
            unreadCount: unreadCount
        )
    }
}

/// Triggered when a message is updated.
public struct MessageUpdatedEvent: ChannelSpecificEvent {
    /// The use who updated the message.
    public let user: ChatUser
    
    /// The channel identifier the message is sent to.
    public let cid: ChannelId
    
    /// The updated message.
    public let message: ChatMessage
    
    /// The event timestamp.
    public let createdAt: Date
}

struct MessageUpdatedEventDTO: EventWithPayload {
    let user: UserPayload
    let cid: ChannelId
    let message: MessagePayload
    let createdAt: Date
    let payload: Any
    
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
            let messageDTO = session.message(id: message.id)
        else { return nil }
        
        return MessageUpdatedEvent(
            user: userDTO.asModel(),
            cid: cid,
            message: messageDTO.asModel(),
            createdAt: createdAt
        )
    }
}

public struct MessageDeletedEvent: MessageSpecificEvent {
    public let userId: UserId
    public let cid: ChannelId
    public let messageId: MessageId
    public let deletedAt: Date
    
    let payload: Any
    
    init(from response: EventPayload) throws {
        userId = try response.value(at: \.user?.id)
        cid = try response.value(at: \.cid)
        messageId = try response.value(at: \.message?.id)
        deletedAt = try response.value(at: \.message?.deletedAt)
        payload = response
    }
}

/// `ChannelReadEvent`, this event tells that User has mark read all messages in channel.
public typealias ChannelReadEvent = MessageReadEvent

/// `ChannelReadEvent`, this event tells that User has mark read all messages in channel.
public struct MessageReadEvent: UserSpecificEvent, ChannelSpecificEvent {
    public let userId: UserId
    public let cid: ChannelId
    public let readAt: Date
    public let unreadCount: UnreadCount?
    
    let payload: Any
    
    init(from response: EventPayload) throws {
        userId = try response.value(at: \.user?.id)
        cid = try response.value(at: \.cid)
        readAt = try response.value(at: \.createdAt)
        unreadCount = try? response.value(at: \.unreadCount)
        payload = response
    }
}

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

/// Triggered when a new message is deleted.
public struct MessageDeletedEvent: ChannelSpecificEvent {
    /// The user who deleted the message.
    public let user: ChatUser
    
    /// The channel identifier the message lives in.
    public let cid: ChannelId
    
    /// The deleted message.
    public let message: ChatMessage
    
    /// The event timestamp.
    public let createdAt: Date
}

struct MessageDeletedEventDTO: EventWithPayload {
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
        
        return MessageDeletedEvent(
            user: userDTO.asModel(),
            cid: cid,
            message: messageDTO.asModel(),
            createdAt: createdAt
        )
    }
}

/// `ChannelReadEvent`, this event tells that User has mark read all messages in channel.
public typealias ChannelReadEvent = MessageReadEvent

/// `ChannelReadEvent`, this event tells that User has mark read all messages in channel.
public struct MessageReadEvent: ChannelSpecificEvent {
    /// The user who read the channel.
    public let user: ChatUser
    
    /// The identifier of the read channel.
    public let cid: ChannelId
    
    /// The event timestamp.
    public let createdAt: Date
    
    /// The unread counts of the current user.
    public let unreadCount: UnreadCount?
}

struct MessageReadEventDTO: EventWithPayload {
    let user: UserPayload
    let cid: ChannelId
    let createdAt: Date
    let unreadCount: UnreadCount?
    let payload: Any
    
    init(from response: EventPayload) throws {
        user = try response.value(at: \.user)
        cid = try response.value(at: \.cid)
        createdAt = try response.value(at: \.createdAt)
        unreadCount = try? response.value(at: \.unreadCount)
        payload = response
    }
    
    func toDomainEvent(session: DatabaseSession) -> Event? {
        guard let userDTO = session.user(id: user.id) else { return nil }
        
        return MessageReadEvent(
            user: userDTO.asModel(),
            cid: cid,
            createdAt: createdAt,
            unreadCount: unreadCount
        )
    }
}

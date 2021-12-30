//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// Triggered when a new message is sent to channel.
public struct MessageNewEvent: ChannelSpecificEvent, HasUnreadCount {
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
}

class MessageNewEventDTO: EventDTO {
    let user: UserPayload
    let cid: ChannelId
    let message: MessagePayload
    let createdAt: Date
    let watcherCount: Int?
    let unreadCount: UnreadCount?
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
            let channelDTO = session.channel(cid: cid)
        else { return nil }
        
        return MessageNewEvent(
            user: userDTO.asModel(),
            message: messageDTO.asModel(),
            channel: channelDTO.asModel(),
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
    public var cid: ChannelId { channel.cid }
    
    /// The channel a message is sent to.
    public let channel: ChatChannel
    
    /// The updated message.
    public let message: ChatMessage
    
    /// The event timestamp.
    public let createdAt: Date
}

class MessageUpdatedEventDTO: EventDTO {
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
        
        return MessageUpdatedEvent(
            user: userDTO.asModel(),
            channel: channelDTO.asModel(),
            message: messageDTO.asModel(),
            createdAt: createdAt
        )
    }
}

/// Triggered when a new message is deleted.
public struct MessageDeletedEvent: ChannelSpecificEvent {
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

    /// A Boolean value indicating wether it is an hard delete or not.
    public let isHardDelete: Bool
}

class MessageDeletedEventDTO: EventDTO {
    let user: UserPayload?
    let cid: ChannelId
    let message: MessagePayload
    let createdAt: Date
    let payload: EventPayload
    let hardDelete: Bool
    
    init(from response: EventPayload) throws {
        user = try? response.value(at: \.user)
        cid = try response.value(at: \.cid)
        message = try response.value(at: \.message)
        createdAt = try response.value(at: \.createdAt)
        payload = response
        hardDelete = response.hardDelete
    }
    
    func toDomainEvent(session: DatabaseSession) -> Event? {
        guard
            let messageDTO = session.message(id: message.id),
            let channelDTO = session.channel(cid: cid)
        else { return nil }
        
        let userDTO = user.flatMap { session.user(id: $0.id) }
        
        return MessageDeletedEvent(
            user: userDTO?.asModel(),
            channel: channelDTO.asModel(),
            message: messageDTO.asModel(),
            createdAt: createdAt,
            isHardDelete: hardDelete
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
    public var cid: ChannelId { channel.cid }
    
    /// The read channel.
    public let channel: ChatChannel
    
    /// The event timestamp.
    public let createdAt: Date
    
    /// The unread counts of the current user.
    public let unreadCount: UnreadCount?
}

class MessageReadEventDTO: EventDTO {
    let user: UserPayload
    let cid: ChannelId
    let createdAt: Date
    let unreadCount: UnreadCount?
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
            let channelDTO = session.channel(cid: cid)
        else { return nil }
        
        return MessageReadEvent(
            user: userDTO.asModel(),
            channel: channelDTO.asModel(),
            createdAt: createdAt,
            unreadCount: unreadCount
        )
    }
}

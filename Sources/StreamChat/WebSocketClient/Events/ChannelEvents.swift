//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// Triggered when a channel is updated.
public struct ChannelUpdatedEvent: ChannelSpecificEvent {
    /// The identifier of updated channel.
    public var cid: ChannelId { channel.cid }
    
    /// The updated channel.
    public let channel: ChatChannel
    
    /// The user who updated the channel.
    public let user: ChatUser?
    
    /// The message which updated the channel.
    public let message: ChatMessage?
    
    /// The event timestamp.
    public let createdAt: Date
}

struct ChannelUpdatedEventDTO: EventDTO {
    let channel: ChannelDetailPayload
    let user: UserPayload?
    let message: MessagePayload?
    let createdAt: Date
    let payload: EventPayload
    
    init(from response: EventPayload) throws {
        channel = try response.value(at: \.channel)
        user = try? response.value(at: \.user)
        message = try? response.value(at: \.message)
        createdAt = try response.value(at: \.createdAt)
        payload = response
    }
    
    func toDomainEvent(session: DatabaseSession) -> Event? {
        guard let channelDTO = session.channel(cid: channel.cid) else { return nil }
                    
        let userDTO = user.flatMap { session.user(id: $0.id) }
        let messageDTO = message.flatMap { session.message(id: $0.id) }
        
        return ChannelUpdatedEvent(
            channel: channelDTO.asModel(),
            user: userDTO?.asModel(),
            message: messageDTO?.asModel(),
            createdAt: createdAt
        )
    }
}

/// Triggered when a channel is deleted.
public struct ChannelDeletedEvent: ChannelSpecificEvent {
    /// The identifier of deleted channel.
    public var cid: ChannelId { channel.cid }
    
    /// The deleted channel.
    public let channel: ChatChannel
    
    /// The user who deleted the channel.
    public let user: ChatUser?
    
    /// The event timestamp.
    public let createdAt: Date
}

struct ChannelDeletedEventDTO: EventDTO {
    let user: UserPayload?
    let channel: ChannelDetailPayload
    let createdAt: Date
    let payload: EventPayload
    
    init(from response: EventPayload) throws {
        user = try? response.value(at: \.user)
        channel = try response.value(at: \.channel)
        createdAt = try response.value(at: \.createdAt)
        payload = response
    }
    
    func toDomainEvent(session: DatabaseSession) -> Event? {
        guard let channelDTO = session.channel(cid: channel.cid) else { return nil }
                    
        let userDTO = user.flatMap { session.user(id: $0.id) }
        
        return ChannelDeletedEvent(
            channel: channelDTO.asModel(),
            user: userDTO?.asModel(),
            createdAt: createdAt
        )
    }
}

/// Triggered when a channel is truncated.
public struct ChannelTruncatedEvent: ChannelSpecificEvent {
    /// The identifier of deleted channel.
    public var cid: ChannelId { channel.cid }
    
    /// The truncated channel.
    public let channel: ChatChannel
    
    /// The user who truncated a channel.
    public let user: ChatUser?
    
    /// The event timestamp.
    public let createdAt: Date
}

struct ChannelTruncatedEventDTO: EventDTO {
    let channel: ChannelDetailPayload
    let user: UserPayload?
    let createdAt: Date
    let payload: EventPayload
    
    init(from response: EventPayload) throws {
        channel = try response.value(at: \.channel)
        user = try? response.value(at: \.user)
        createdAt = try response.value(at: \.createdAt)
        payload = response
    }
    
    func toDomainEvent(session: DatabaseSession) -> Event? {
        guard let channelDTO = session.channel(cid: channel.cid) else { return nil }
                    
        let userDTO = user.flatMap { session.user(id: $0.id) }
        
        return ChannelTruncatedEvent(
            channel: channelDTO.asModel(),
            user: userDTO?.asModel(),
            createdAt: createdAt
        )
    }
}

/// Triggered when a channel is made visible.
public struct ChannelVisibleEvent: ChannelSpecificEvent {
    /// The channel identifier.
    public let cid: ChannelId
    
    /// The user who made the channel visible.
    public let user: ChatUser
    
    /// The event timestamp.
    public let createdAt: Date
}

struct ChannelVisibleEventDTO: EventDTO {
    let cid: ChannelId
    let user: UserPayload
    let createdAt: Date
    let payload: EventPayload
    
    init(from response: EventPayload) throws {
        cid = try response.value(at: \.cid)
        user = try response.value(at: \.user)
        createdAt = try response.value(at: \.createdAt)
        payload = response
    }
    
    func toDomainEvent(session: DatabaseSession) -> Event? {
        guard let userDTO = session.user(id: user.id) else { return nil }
        
        return ChannelVisibleEvent(
            cid: cid,
            user: userDTO.asModel(),
            createdAt: createdAt
        )
    }
}

/// Triggered when a channel is hidden.
public struct ChannelHiddenEvent: ChannelSpecificEvent {
    /// The hidden channel identifier.
    public let cid: ChannelId
    
    /// The user who hide the channel.
    public let user: ChatUser
    
    /// The flag saying that channel history was cleared.
    public let isHistoryCleared: Bool
    
    /// The date a channel was hidden.
    public let createdAt: Date
}

struct ChannelHiddenEventDTO: EventDTO {
    let cid: ChannelId
    let user: UserPayload
    let isHistoryCleared: Bool
    let createdAt: Date
    let payload: EventPayload
    
    init(from response: EventPayload) throws {
        cid = try response.value(at: \.cid)
        createdAt = try response.value(at: \.createdAt)
        user = try response.value(at: \.user)
        isHistoryCleared = try response.value(at: \.isChannelHistoryCleared)
        payload = response
    }
    
    func toDomainEvent(session: DatabaseSession) -> Event? {
        guard let userDTO = session.user(id: user.id) else { return nil }
        
        return ChannelHiddenEvent(
            cid: cid,
            user: userDTO.asModel(),
            isHistoryCleared: isHistoryCleared,
            createdAt: createdAt
        )
    }
}

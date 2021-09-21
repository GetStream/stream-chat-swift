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

struct ChannelUpdatedEventDTO: EventWithPayload {
    let channel: ChannelDetailPayload
    let user: UserPayload?
    let message: MessagePayload?
    let createdAt: Date
    let payload: Any
    
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

public struct ChannelDeletedEvent: ChannelSpecificEvent {
    public let cid: ChannelId
    public let deletedAt: Date
    
    let payload: Any
    
    init(from response: EventPayload) throws {
        cid = try response.value(at: \.cid)
        deletedAt = try response.value(at: \.channel?.deletedAt)
        payload = response
    }
}

public struct ChannelTruncatedEvent: ChannelSpecificEvent {
    public let cid: ChannelId
    let payload: Any
    
    init(from response: EventPayload) throws {
        cid = try response.value(at: \.cid)
        payload = response
    }
}

public struct ChannelVisibleEvent: ChannelSpecificEvent {
    public let cid: ChannelId
    let payload: Any

    init(from response: EventPayload) throws {
        cid = try response.value(at: \.cid)
        payload = response
    }
}

public struct ChannelHiddenEvent: ChannelSpecificEvent {
    public let cid: ChannelId
    public let hiddenAt: Date
    public let isHistoryCleared: Bool
    let payload: Any

    init(from response: EventPayload) throws {
        cid = try response.value(at: \.cid)
        hiddenAt = try response.value(at: \.createdAt)
        isHistoryCleared = try response.value(at: \.isChannelHistoryCleared)
        payload = response
    }
}

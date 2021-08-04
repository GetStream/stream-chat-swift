//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

public struct MessageNewEvent: MessageSpecificEvent {
    public let userId: UserId
    public let cid: ChannelId
    public let messageId: MessageId
    public let createdAt: Date
    public let watcherCount: Int?
    public let unreadCount: UnreadCount?
    
    var savedData: SavedEventData?
    let payload: Any
    
    init(from response: EventPayload) throws {
        userId = try response.value(at: \.user?.id)
        cid = try response.value(at: \.cid)
        messageId = try response.value(at: \.message?.id)
        createdAt = try response.value(at: \.message?.createdAt)
        watcherCount = try? response.value(at: \.watcherCount)
        unreadCount = try? response.value(at: \.unreadCount)
        payload = response
    }
}

public struct MessageUpdatedEvent: MessageSpecificEvent {
    public let userId: UserId
    public let cid: ChannelId
    public let messageId: MessageId
    public let updatedAt: Date
    
    var savedData: SavedEventData?
    let payload: Any
    
    init(from response: EventPayload) throws {
        userId = try response.value(at: \.user?.id)
        cid = try response.value(at: \.cid)
        messageId = try response.value(at: \.message?.id)
        updatedAt = try response.value(at: \.message?.updatedAt)
        payload = response
    }
}

public struct MessageDeletedEvent: MessageSpecificEvent {
    public let userId: UserId
    public let cid: ChannelId
    public let messageId: MessageId
    public let deletedAt: Date
    
    var savedData: SavedEventData?
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
    
    var savedData: SavedEventData?
    let payload: Any
    
    init(from response: EventPayload) throws {
        userId = try response.value(at: \.user?.id)
        cid = try response.value(at: \.cid)
        readAt = try response.value(at: \.createdAt)
        unreadCount = try? response.value(at: \.unreadCount)
        payload = response
    }
}

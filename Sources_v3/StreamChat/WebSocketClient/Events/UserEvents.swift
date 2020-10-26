//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

public struct UserPresenceChangedEvent<ExtraData: ExtraDataTypes>: EventWithUserPayload {
    public let userId: UserId
    public let createdAt: Date?
    
    let payload: Any
    
    init(from response: EventPayload<ExtraData>) throws {
        userId = try response.value(at: \.user?.id)
        createdAt = response.createdAt
        payload = response
    }
}

public struct UserUpdatedEvent<ExtraData: ExtraDataTypes>: EventWithUserPayload, EventWithChannelId {
    public let cid: ChannelId
    public let userId: UserId
    public let createdAt: Date?
    
    let payload: Any
    
    init(from response: EventPayload<ExtraData>) throws {
        cid = try response.value(at: \.cid)
        userId = try response.value(at: \.user?.id)
        createdAt = response.createdAt
        payload = response
    }
}

// MARK: - User Watching

public struct UserWatchingEvent<ExtraData: ExtraDataTypes>: EventWithUserPayload, EventWithChannelId {
    public let cid: ChannelId
    public let userId: UserId
    public let createdAt: Date?
    public let watcherCount: Int
    public let isStarted: Bool
    
    let payload: Any
    
    init(from response: EventPayload<ExtraData>) throws {
        cid = try response.value(at: \.cid)
        userId = try response.value(at: \.user?.id)
        createdAt = response.createdAt
        watcherCount = try response.value(at: \.watcherCount)
        isStarted = response.eventType == .userStartWatching
        payload = response
    }
}

// MARK: - User Ban

public struct UserBannedEvent<ExtraData: ExtraDataTypes>: EventWithUserPayload, EventWithOwnerPayload, EventWithChannelId {
    public let cid: ChannelId
    public let userId: UserId
    public let ownerId: UserId
    public let createdAt: Date?
    public let reason: String?
    public let expiredAt: Date?
    
    let payload: Any
    
    init(from response: EventPayload<ExtraData>) throws {
        cid = try response.value(at: \.cid)
        userId = try response.value(at: \.user?.id)
        ownerId = try response.value(at: \.createdBy?.id)
        createdAt = response.createdAt
        reason = response.banReason
        expiredAt = response.banExpiredAt
        payload = response
    }
}

public struct UserUnbannedEvent<ExtraData: ExtraDataTypes>: EventWithUserPayload, EventWithChannelId {
    public let cid: ChannelId
    public let userId: UserId
    public let createdAt: Date?
    
    let payload: Any
    
    init(from response: EventPayload<ExtraData>) throws {
        cid = try response.value(at: \.cid)
        userId = try response.value(at: \.user?.id)
        createdAt = response.createdAt
        payload = response
    }
}

//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// Triggered when user status changes (eg. online, offline, away, etc.)
public struct UserPresenceChangedEvent: Event {
    /// The user the status changed for
    public let user: ChatUser
    
    /// The event timestamp
    public let createdAt: Date?
}

struct UserPresenceChangedEventDTO: EventWithPayload {
    let user: UserPayload
    let createdAt: Date
    let payload: Any
    
    init(from response: EventPayload) throws {
        user = try response.value(at: \.user)
        createdAt = try response.value(at: \.createdAt)
        payload = response
    }
    
    func toDomainEvent(session: DatabaseSession) -> Event? {
        guard let userDTO = session.user(id: user.id) else { return nil }
        
        return UserPresenceChangedEvent(
            user: userDTO.asModel(),
            createdAt: createdAt
        )
    }
}

/// Triggered when user is updated
public struct UserUpdatedEvent: Event {
    /// The updated user
    public let user: ChatUser
    
    /// The event timestamp
    public let createdAt: Date?
}

struct UserUpdatedEventDTO: EventWithPayload {
    let user: UserPayload
    let createdAt: Date
    let payload: Any
    
    init(from response: EventPayload) throws {
        user = try response.value(at: \.user)
        createdAt = try response.value(at: \.createdAt)
        payload = response
    }
    
    func toDomainEvent(session: DatabaseSession) -> Event? {
        guard let userDTO = session.user(id: user.id) else { return nil }
        
        return UserUpdatedEvent(
            user: userDTO.asModel(),
            createdAt: createdAt
        )
    }
}

// MARK: - User Watching

public struct UserWatchingEvent: UserSpecificEvent, ChannelSpecificEvent {
    public let cid: ChannelId
    public let userId: UserId
    public let createdAt: Date
    public let watcherCount: Int
    public let isStarted: Bool
    
    let payload: Any
    
    init(from response: EventPayload) throws {
        cid = try response.value(at: \.cid)
        userId = try response.value(at: \.user?.id)
        createdAt = try response.value(at: \.createdAt)
        watcherCount = try response.value(at: \.watcherCount)
        isStarted = response.eventType == .userStartWatching
        payload = response
    }
}

// MARK: - User Ban

public struct UserGloballyBannedEvent: UserSpecificEvent {
    var userId: UserId
    var createdAt: Date?
    var payload: Any
    
    init(from response: EventPayload) throws {
        userId = try response.value(at: \.user?.id)
        createdAt = response.createdAt
        payload = response
    }
}

public struct UserBannedEvent: UserSpecificEvent, ChannelSpecificEvent {
    public let cid: ChannelId
    public let userId: UserId
    public let ownerId: UserId
    public let createdAt: Date?
    public let reason: String?
    public let expiredAt: Date?
    
    let payload: Any
    
    init(from response: EventPayload) throws {
        cid = try response.value(at: \.cid)
        userId = try response.value(at: \.user?.id)
        ownerId = try response.value(at: \.createdBy?.id)
        createdAt = response.createdAt
        reason = response.banReason
        expiredAt = response.banExpiredAt
        payload = response
    }
}

public struct UserGloballyUnbannedEvent: UserSpecificEvent {
    var userId: UserId
    var createdAt: Date?
    var payload: Any
    
    init(from response: EventPayload) throws {
        userId = try response.value(at: \.user?.id)
        createdAt = response.createdAt
        payload = response
    }
}

public struct UserUnbannedEvent: UserSpecificEvent, ChannelSpecificEvent {
    public let cid: ChannelId
    public let userId: UserId
    public let createdAt: Date?
    
    let payload: Any
    
    init(from response: EventPayload) throws {
        cid = try response.value(at: \.cid)
        userId = try response.value(at: \.user?.id)
        createdAt = response.createdAt
        payload = response
    }
}

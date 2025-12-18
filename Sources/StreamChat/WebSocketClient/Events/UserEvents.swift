//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// Triggered when user status changes (eg. online, offline, away, etc.)
public final class UserPresenceChangedEvent: Event {
    /// The user the status changed for
    public let user: ChatUser

    /// The event timestamp
    public let createdAt: Date?

    init(user: ChatUser, createdAt: Date?) {
        self.user = user
        self.createdAt = createdAt
    }
}

final class UserPresenceChangedEventDTO: EventDTO {
    let user: UserPayload
    let createdAt: Date
    let payload: EventPayload

    init(from response: EventPayload) throws {
        user = try response.value(at: \.user)
        createdAt = try response.value(at: \.createdAt)
        payload = response
    }

    func toDomainEvent(session: DatabaseSession) -> Event? {
        guard let userDTO = session.user(id: user.id) else { return nil }

        return try? UserPresenceChangedEvent(
            user: userDTO.asModel(),
            createdAt: createdAt
        )
    }
}

/// Triggered when user is updated
public final class UserUpdatedEvent: Event {
    /// The updated user
    public let user: ChatUser

    /// The event timestamp
    public let createdAt: Date?

    init(user: ChatUser, createdAt: Date?) {
        self.user = user
        self.createdAt = createdAt
    }
}

final class UserUpdatedEventDTO: EventDTO {
    let user: UserPayload
    let createdAt: Date
    let payload: EventPayload

    init(from response: EventPayload) throws {
        user = try response.value(at: \.user)
        createdAt = try response.value(at: \.createdAt)
        payload = response
    }

    func toDomainEvent(session: DatabaseSession) -> Event? {
        guard let userDTO = session.user(id: user.id) else { return nil }

        return try? UserUpdatedEvent(
            user: userDTO.asModel(),
            createdAt: createdAt
        )
    }
}

// MARK: - User Watching

/// Triggered when a user starts/stops watching a channel
public final class UserWatchingEvent: ChannelSpecificEvent {
    /// The channel identifier a user started/stopped watching
    public let cid: ChannelId

    /// The event timestamp
    public let createdAt: Date

    /// The user who started/stopped watching a channel
    public let user: ChatUser

    /// The # of channel watchers
    public let watcherCount: Int

    /// The flag saying if watching was started or stopped
    public let isStarted: Bool

    init(cid: ChannelId, createdAt: Date, user: ChatUser, watcherCount: Int, isStarted: Bool) {
        self.cid = cid
        self.createdAt = createdAt
        self.user = user
        self.watcherCount = watcherCount
        self.isStarted = isStarted
    }
}

final class UserWatchingEventDTO: EventDTO {
    let cid: ChannelId
    let user: UserPayload
    let createdAt: Date
    let watcherCount: Int
    let isStarted: Bool
    let payload: EventPayload

    init(from response: EventPayload) throws {
        cid = try response.value(at: \.cid)
        user = try response.value(at: \.user)
        createdAt = try response.value(at: \.createdAt)
        watcherCount = try response.value(at: \.watcherCount)
        isStarted = response.eventType == .userStartWatching
        payload = response
    }

    func toDomainEvent(session: DatabaseSession) -> Event? {
        guard let userDTO = session.user(id: user.id) else { return nil }

        return try? UserWatchingEvent(
            cid: cid,
            createdAt: createdAt,
            user: userDTO.asModel(),
            watcherCount: watcherCount,
            isStarted: isStarted
        )
    }
}

// MARK: - User Ban

/// Triggered when user is banned not in a specific channel but globally.
public final class UserGloballyBannedEvent: Event {
    /// The banned user
    public let user: ChatUser

    /// The event timestamp
    public let createdAt: Date

    init(user: ChatUser, createdAt: Date) {
        self.user = user
        self.createdAt = createdAt
    }
}

final class UserGloballyBannedEventDTO: EventDTO {
    let user: UserPayload
    let createdAt: Date
    let payload: EventPayload

    init(from response: EventPayload) throws {
        user = try response.value(at: \.user)
        createdAt = try response.value(at: \.createdAt)
        payload = response
    }

    func toDomainEvent(session: DatabaseSession) -> Event? {
        guard let userDTO = session.user(id: user.id) else { return nil }

        return try? UserGloballyBannedEvent(
            user: userDTO.asModel(),
            createdAt: createdAt
        )
    }
}

/// Triggered when user is banned in a specific channel
public final class UserBannedEvent: ChannelSpecificEvent {
    /// The channel identifer user is banned at.
    public let cid: ChannelId

    /// The banned user.
    public let user: ChatUser

    /// The identifier of a user who initiated a ban.
    public let ownerId: UserId

    /// The event timestamp
    public let createdAt: Date?

    /// The ban reason.
    public let reason: String?

    /// The ban expiration date.
    public let expiredAt: Date?

    /// A boolean value indicating if the ban is a shadowed ban or not.
    public let isShadowBan: Bool?

    init(cid: ChannelId, user: ChatUser, ownerId: UserId, createdAt: Date?, reason: String?, expiredAt: Date?, isShadowBan: Bool?) {
        self.cid = cid
        self.user = user
        self.ownerId = ownerId
        self.createdAt = createdAt
        self.reason = reason
        self.expiredAt = expiredAt
        self.isShadowBan = isShadowBan
    }
}

final class UserBannedEventDTO: EventDTO {
    let cid: ChannelId
    let user: UserPayload
    let ownerId: UserId
    let createdAt: Date
    let reason: String?
    let expiredAt: Date?
    let payload: EventPayload
    let isShadowBan: Bool?

    init(from response: EventPayload) throws {
        cid = try response.value(at: \.cid)
        user = try response.value(at: \.user)
        ownerId = try response.value(at: \.createdBy?.id)
        createdAt = try response.value(at: \.createdAt)
        reason = response.banReason
        expiredAt = response.banExpiredAt
        payload = response
        isShadowBan = response.shadow
    }

    func toDomainEvent(session: DatabaseSession) -> Event? {
        guard let userDTO = session.user(id: user.id) else { return nil }

        return try? UserBannedEvent(
            cid: cid,
            user: userDTO.asModel(),
            ownerId: ownerId,
            createdAt: createdAt,
            reason: reason,
            expiredAt: expiredAt,
            isShadowBan: isShadowBan
        )
    }
}

/// Triggered when user is removed from global ban.
public final class UserGloballyUnbannedEvent: Event {
    /// The unbanned user.
    public let user: ChatUser

    /// The event timestamp
    public let createdAt: Date

    init(user: ChatUser, createdAt: Date) {
        self.user = user
        self.createdAt = createdAt
    }
}

final class UserGloballyUnbannedEventDTO: EventDTO {
    let user: UserPayload
    let createdAt: Date
    let payload: EventPayload

    init(from response: EventPayload) throws {
        user = try response.value(at: \.user)
        createdAt = try response.value(at: \.createdAt)
        payload = response
    }

    func toDomainEvent(session: DatabaseSession) -> Event? {
        guard let userDTO = session.user(id: user.id) else { return nil }

        return try? UserGloballyUnbannedEvent(
            user: userDTO.asModel(),
            createdAt: createdAt
        )
    }
}

/// Triggered when banned user is unbanned in a specific channel
public final class UserUnbannedEvent: ChannelSpecificEvent {
    /// The channel identifer user is unbanned at.
    public let cid: ChannelId

    /// The unbanned user.
    public let user: ChatUser

    /// The event timestamp
    public let createdAt: Date?

    init(cid: ChannelId, user: ChatUser, createdAt: Date?) {
        self.cid = cid
        self.user = user
        self.createdAt = createdAt
    }
}

final class UserUnbannedEventDTO: EventDTO {
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

        return try? UserUnbannedEvent(
            cid: cid,
            user: userDTO.asModel(),
            createdAt: createdAt
        )
    }
}

/// Triggered when the messages of a banned user should be deleted.
public final class UserMessagesDeletedEvent: Event {
    /// The banned user.
    public let user: ChatUser

    /// If the messages should be hard deleted or not.
    public let hardDelete: Bool

    /// The event timestamp
    public let createdAt: Date

    init(user: ChatUser, hardDelete: Bool, createdAt: Date) {
        self.user = user
        self.hardDelete = hardDelete
        self.createdAt = createdAt
    }
}

final class UserMessagesDeletedEventDTO: EventDTO {
    let user: UserPayload
    let createdAt: Date
    let payload: EventPayload

    init(from response: EventPayload) throws {
        user = try response.value(at: \.user)
        createdAt = try response.value(at: \.createdAt)
        payload = response
    }

    func toDomainEvent(session: DatabaseSession) -> Event? {
        if let userDTO = session.user(id: user.id),
           let userModel = try? userDTO.asModel() {
            return UserMessagesDeletedEvent(
                user: userModel,
                hardDelete: payload.hardDelete,
                createdAt: createdAt
            )
        }

        return UserMessagesDeletedEvent(
            user: user.asModel(),
            hardDelete: payload.hardDelete,
            createdAt: createdAt
        )
    }
}

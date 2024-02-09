//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// Triggered when user status changes (eg. online, offline, away, etc.)
public struct UserPresenceChangedEvent: Event {
    /// The user the status changed for
    public let user: ChatUser

    /// The event timestamp
    public let createdAt: Date?
}

/// Triggered when user is updated
public struct UserUpdatedEvent: Event {
    /// The updated user
    public let user: ChatUser

    /// The event timestamp
    public let createdAt: Date?
}

// MARK: - User Watching

/// Triggered when a user starts/stops watching a channel
public struct UserWatchingEvent: ChannelSpecificEvent {
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
}

// MARK: - User Ban

/// Triggered when user is banned not in a specific channel but globally.
public struct UserGloballyBannedEvent: Event {
    /// The banned user
    public let user: ChatUser

    /// The event timestamp
    public let createdAt: Date
}

/// Triggered when user is banned in a specific channel
public struct UserBannedEvent: ChannelSpecificEvent {
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
}

/// Triggered when user is removed from global ban.
public struct UserGloballyUnbannedEvent: Event {
    /// The unbanned user.
    public let user: ChatUser

    /// The event timestamp
    public let createdAt: Date
}

/// Triggered when banned user is unbanned in a specific channel
public struct UserUnbannedEvent: ChannelSpecificEvent {
    /// The channel identifer user is unbanned at.
    public let cid: ChannelId

    /// The unbanned user.
    public let user: ChatUser

    /// The event timestamp
    public let createdAt: Date?
}

//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Triggered when a channel is updated.
public final class ChannelUpdatedEvent: ChannelSpecificEvent {
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

    init(channel: ChatChannel, user: ChatUser?, message: ChatMessage?, createdAt: Date) {
        self.channel = channel
        self.user = user
        self.message = message
        self.createdAt = createdAt
    }
}

extension ChannelUpdatedEventDTO: EventDTO {
    func toDomainEvent(session: any DatabaseSession) -> (any Event)? {
        guard let channelDTO = (try? ChannelId(cid: channel.cid)).flatMap(session.channel(cid:)) else { return nil }

        let userDTO = user.flatMap { session.user(id: $0.id) }
        let messageDTO = message.flatMap { session.message(id: $0.id) }

        return try? ChannelUpdatedEvent(
            channel: channelDTO.asModel(),
            user: userDTO?.asModel(),
            message: messageDTO?.asModel(),
            createdAt: createdAt
        )
    }
}

/// Triggered when a channel is deleted.
public final class ChannelDeletedEvent: ChannelSpecificEvent {
    /// The identifier of deleted channel.
    public var cid: ChannelId { channel.cid }

    /// The deleted channel.
    public let channel: ChatChannel

    /// The user who deleted the channel.
    public let user: ChatUser?

    /// The event timestamp.
    public let createdAt: Date

    init(channel: ChatChannel, user: ChatUser?, createdAt: Date) {
        self.channel = channel
        self.user = user
        self.createdAt = createdAt
    }
}

extension ChannelDeletedEventDTO: EventDTO {
    func toDomainEvent(session: any DatabaseSession) -> (any Event)? {
        guard let channelDTO = (try? ChannelId(cid: channel.cid)).flatMap(session.channel(cid:)) else { return nil }

        let userDTO = user.flatMap { session.user(id: $0.id) }

        return try? ChannelDeletedEvent(
            channel: channelDTO.asModel(),
            user: userDTO?.asModel(),
            createdAt: createdAt
        )
    }
}

/// Triggered when a channel is truncated.
public final class ChannelTruncatedEvent: ChannelSpecificEvent {
    /// The identifier of deleted channel.
    public var cid: ChannelId { channel.cid }

    /// The truncated channel.
    public let channel: ChatChannel

    /// The user who truncated a channel.
    public let user: ChatUser?

    /// The system message accompanied with the truncated event.
    public let message: ChatMessage?

    /// The event timestamp.
    public let createdAt: Date

    init(channel: ChatChannel, user: ChatUser?, message: ChatMessage?, createdAt: Date) {
        self.channel = channel
        self.user = user
        self.message = message
        self.createdAt = createdAt
    }
}

extension ChannelTruncatedEventDTO: EventDTO {
    func toDomainEvent(session: any DatabaseSession) -> (any Event)? {
        guard let channelDTO = (try? ChannelId(cid: channel.cid)).flatMap(session.channel(cid:)) else { return nil }

        let userDTO = user.flatMap { session.user(id: $0.id) }
        let messageDTO = message.flatMap { session.message(id: $0.id) }

        return try? ChannelTruncatedEvent(
            channel: channelDTO.asModel(),
            user: userDTO?.asModel(),
            message: messageDTO?.asModel(),
            createdAt: createdAt
        )
    }
}

/// Triggered when a channel is made visible.
public final class ChannelVisibleEvent: ChannelSpecificEvent {
    /// The channel identifier.
    public let cid: ChannelId

    /// The user who made the channel visible.
    public let user: ChatUser

    /// The event timestamp.
    public let createdAt: Date

    init(cid: ChannelId, user: ChatUser, createdAt: Date) {
        self.cid = cid
        self.user = user
        self.createdAt = createdAt
    }
}

extension ChannelVisibleEventDTO: EventDTO {
    func toDomainEvent(session: any DatabaseSession) -> (any Event)? {
        guard let user = user, let userDTO = session.user(id: user.id) else { return nil }
        guard let cidString = cid, let channelId = try? ChannelId(cid: cidString) else { return nil }

        return try? ChannelVisibleEvent(
            cid: channelId,
            user: userDTO.asModel(),
            createdAt: createdAt
        )
    }
}

/// Triggered when a channel is hidden.
public final class ChannelHiddenEvent: ChannelSpecificEvent {
    /// The hidden channel identifier.
    public let cid: ChannelId

    /// The user who hide the channel.
    public let user: ChatUser

    /// The flag saying that channel history was cleared.
    public let isHistoryCleared: Bool

    /// The date a channel was hidden.
    public let createdAt: Date

    init(cid: ChannelId, user: ChatUser, isHistoryCleared: Bool, createdAt: Date) {
        self.cid = cid
        self.user = user
        self.isHistoryCleared = isHistoryCleared
        self.createdAt = createdAt
    }
}

extension ChannelHiddenEventDTO: EventDTO {
    func toDomainEvent(session: any DatabaseSession) -> (any Event)? {
        guard let user = user, let userDTO = session.user(id: user.id) else { return nil }
        guard let cidString = cid, let channelId = try? ChannelId(cid: cidString) else { return nil }

        return try? ChannelHiddenEvent(
            cid: channelId,
            user: userDTO.asModel(),
            isHistoryCleared: clearHistory,
            createdAt: createdAt
        )
    }
}

//
// Copyright © 2024 Stream.io Inc. All rights reserved.
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

/// Triggered when a channel is truncated.
public struct ChannelTruncatedEvent: ChannelSpecificEvent {
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

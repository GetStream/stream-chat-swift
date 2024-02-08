//
// Copyright © 2024 Stream.io Inc. All rights reserved.
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

    /// A Boolean value indicating whether it is an hard delete or not.
    public let isHardDelete: Bool
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

// Triggered when the current user creates a new message and is pending to be sent.
public struct NewMessagePendingEvent: Event {
    public var message: ChatMessage
}

// Triggered when a message failed being sent.
public struct NewMessageErrorEvent: Event {
    public let messageId: MessageId
    public let error: Error
}

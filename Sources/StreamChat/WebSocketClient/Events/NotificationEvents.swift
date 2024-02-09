//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// Triggered when a new message is sent to a channel the current user is member of.
public struct NotificationMessageNewEvent: ChannelSpecificEvent, HasUnreadCount {
    /// The identifier of a channel a message is sent to.
    public var cid: ChannelId { channel.cid }

    /// The channel a message was sent to.
    public let channel: ChatChannel

    /// The sent message.
    public let message: ChatMessage

    /// The event timestamp.
    public let createdAt: Date

    /// The unread counts of the current user.
    public let unreadCount: UnreadCount?
}

/// Triggered when all channels the current user is member of are marked as read.
public struct NotificationMarkAllReadEvent: Event, HasUnreadCount {
    /// The current user.
    public let user: ChatUser

    /// The unread counts of the current user.
    public let unreadCount: UnreadCount?

    /// The event timestamp.
    public let createdAt: Date
}

/// Triggered when a channel the current user is member of is marked as read.
public struct NotificationMarkReadEvent: ChannelSpecificEvent, HasUnreadCount {
    /// The current user.
    public let user: ChatUser

    /// The read channel identifier.
    public let cid: ChannelId

    /// The unread counts of the current user.
    public let unreadCount: UnreadCount?

    /// The id of the last read message id
    public let lastReadMessageId: MessageId?

    /// The event timestamp.
    public let createdAt: Date
}

/// Triggered when a channel the current user is member of is marked as unread.
public struct NotificationMarkUnreadEvent: ChannelSpecificEvent {
    /// The current user.
    public let user: ChatUser

    /// The read channel identifier.
    public let cid: ChannelId

    /// The event timestamp.
    public let createdAt: Date

    /// The id of the first unread message id
    public let firstUnreadMessageId: MessageId

    /// The id of the last read message id
    public let lastReadMessageId: MessageId?

    /// The timestamp of the last read message
    public let lastReadAt: Date

    /// The number of unread messages for the channel
    public let unreadMessagesCount: Int
}

/// Triggered when current user mutes/unmutes a user.
public struct NotificationMutesUpdatedEvent: Event {
    /// The current user.
    public let currentUser: CurrentChatUser

    /// The event timestamp.
    public let createdAt: Date
}

/// Triggered when the current user is added to the channel member list.
public struct NotificationAddedToChannelEvent: ChannelSpecificEvent, HasUnreadCount {
    /// The identifier of a channel a message is sent to.
    public var cid: ChannelId { channel.cid }

    /// The channel the current user was added to.
    public let channel: ChatChannel

    /// The unread counts of the current user.
    public let unreadCount: UnreadCount?

    /// The membership information of the current user.
    public let member: ChatChannelMember

    /// The event timestamp.
    public let createdAt: Date
}

/// Triggered when the current user is removed from a channel member list.
public struct NotificationRemovedFromChannelEvent: ChannelSpecificEvent {
    /// The user who removed the current user from channel members.
    public let user: ChatUser

    /// The channel identifier the current user was removed from.
    public let cid: ChannelId

    /// The current user.
    public let member: ChatChannelMember

    /// The event timestamp.
    public let createdAt: Date
}

/// Triggered when current user mutes/unmutes a channel.
public struct NotificationChannelMutesUpdatedEvent: Event {
    /// The current user.
    public let currentUser: CurrentChatUser

    /// The event timestamp.
    public let createdAt: Date
}

/// Triggered when current user is invited to a channel.
public struct NotificationInvitedEvent: MemberEvent, ChannelSpecificEvent {
    /// The inviter.
    public let user: ChatUser

    /// The channel identifier the current user was invited to.
    public let cid: ChannelId

    /// The membership information of the current user.
    public let member: ChatChannelMember

    /// The event timestamp.
    public let createdAt: Date
}

/// Triggered when the current user accepts an invite to a channel.
public struct NotificationInviteAcceptedEvent: MemberEvent, ChannelSpecificEvent {
    /// The inviter.
    public let user: ChatUser

    /// The channel identifier the current user has become a member of.
    public var cid: ChannelId { channel.cid }

    /// The channel the current user has become a member of.
    public let channel: ChatChannel

    /// The membership information of the current user.
    public let member: ChatChannelMember

    /// The event timestamp.
    public let createdAt: Date
}

/// Triggered when the current user rejects an invite to a channel.
public struct NotificationInviteRejectedEvent: MemberEvent, ChannelSpecificEvent {
    /// The inviter.
    public let user: ChatUser

    /// The channel identifier the current user has rejected an intivation to.
    public var cid: ChannelId { channel.cid }

    /// The channel the current user has rejected an intivation to.
    public let channel: ChatChannel

    /// The membership information of the current user.
    public let member: ChatChannelMember

    /// The event timestamp.
    public let createdAt: Date
}

/// Triggered when a channel is deleted, this event is delivered to all channel members
public struct NotificationChannelDeletedEvent: ChannelSpecificEvent {
    /// The cid of the deleted channel
    public let cid: ChannelId

    /// The channel that was deleted
    public let channel: ChatChannel

    /// The event timestamp.
    public let createdAt: Date
}

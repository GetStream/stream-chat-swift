//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// Triggered when a new member is added to a channel.
public struct MemberAddedEvent: MemberEvent, ChannelSpecificEvent {
    /// The user who added a member to a channel.
    public let user: ChatUser

    /// The channel identifier a member was added to.
    public let cid: ChannelId

    /// The memeber that was added to a channel.
    public let member: ChatChannelMember

    /// The event timestamp.
    public let createdAt: Date
}

/// Triggered when a channel member is updated.
public struct MemberUpdatedEvent: MemberEvent, ChannelSpecificEvent {
    /// The user who updated a member.
    public let user: ChatUser

    /// The channel identifier a member was updated in.
    public let cid: ChannelId

    /// The updated member.
    public let member: ChatChannelMember

    /// The event timestamp.
    public let createdAt: Date
}

/// Triggered when a member is removed from a channel.
public struct MemberRemovedEvent: MemberEvent, ChannelSpecificEvent {
    /// The user who stopped being a member.
    public let user: ChatUser

    /// The channel identifier a member was removed from.
    public let cid: ChannelId

    /// The event timestamp.
    public let createdAt: Date
}

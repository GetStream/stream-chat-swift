//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// Triggered a new reaction is added.
public struct ReactionNewEvent: ChannelSpecificEvent {
    /// The use who added a reaction.
    public let user: ChatUser

    /// The channel identifier the message lives in.
    public let cid: ChannelId

    /// The message a reaction is added to.
    public let message: ChatMessage

    /// The reaction added.
    public let reaction: ChatMessageReaction

    /// The event timestamp.
    public let createdAt: Date
}

/// Triggered when a reaction is updated.
public struct ReactionUpdatedEvent: ChannelSpecificEvent {
    /// The use who updated a reaction.
    public let user: ChatUser

    /// The channel identifier the message lives in.
    public let cid: ChannelId

    /// The message a reaction is added to.
    public let message: ChatMessage

    /// The updated reaction.
    public let reaction: ChatMessageReaction

    /// The event timestamp.
    public let createdAt: Date
}

/// Triggered when a reaction is deleted.
public struct ReactionDeletedEvent: ChannelSpecificEvent {
    /// The use who deleted a reaction.
    public let user: ChatUser

    /// The channel identifier the message lives in.
    public let cid: ChannelId

    /// The message a reaction is deleted from.
    public let message: ChatMessage

    /// The deleted reaction.
    public let reaction: ChatMessageReaction

    /// The event timestamp.
    public let createdAt: Date
}

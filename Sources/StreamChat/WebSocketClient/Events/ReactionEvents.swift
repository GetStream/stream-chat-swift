//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Triggered a new reaction is added.
public final class ReactionNewEvent: ChannelSpecificEvent {
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

    init(user: ChatUser, cid: ChannelId, message: ChatMessage, reaction: ChatMessageReaction, createdAt: Date) {
        self.user = user
        self.cid = cid
        self.message = message
        self.reaction = reaction
        self.createdAt = createdAt
    }
}

extension ReactionNewEventDTO: EventDTO {
    func toDomainEvent(session: any DatabaseSession) -> (any Event)? {
        guard let user = user, let message = message, let reaction = reaction else { return nil }
        guard let cidString = cid, let channelId = try? ChannelId(cid: cidString) else { return nil }
        guard
            let userDTO = session.user(id: user.id),
            let messageDTO = session.message(id: message.id),
            let reactionDTO = session.reaction(
                messageId: message.id,
                userId: user.id,
                type: MessageReactionType(rawValue: reaction.type)
            )
        else { return nil }

        return try? ReactionNewEvent(
            user: userDTO.asModel(),
            cid: channelId,
            message: messageDTO.asModel(),
            reaction: reactionDTO.asModel(),
            createdAt: createdAt
        )
    }
}

/// Triggered when a reaction is updated.
public final class ReactionUpdatedEvent: ChannelSpecificEvent {
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

    init(user: ChatUser, cid: ChannelId, message: ChatMessage, reaction: ChatMessageReaction, createdAt: Date) {
        self.user = user
        self.cid = cid
        self.message = message
        self.reaction = reaction
        self.createdAt = createdAt
    }
}

extension ReactionUpdatedEventDTO: EventDTO {
    func toDomainEvent(session: any DatabaseSession) -> (any Event)? {
        guard let user = user, let reaction = reaction else { return nil }
        guard let cidString = cid, let channelId = try? ChannelId(cid: cidString) else { return nil }
        guard
            let userDTO = session.user(id: user.id),
            let messageDTO = session.message(id: message.id),
            let reactionDTO = session.reaction(
                messageId: message.id,
                userId: user.id,
                type: MessageReactionType(rawValue: reaction.type)
            )
        else { return nil }

        return try? ReactionUpdatedEvent(
            user: userDTO.asModel(),
            cid: channelId,
            message: messageDTO.asModel(),
            reaction: reactionDTO.asModel(),
            createdAt: createdAt
        )
    }
}

/// Triggered when a reaction is deleted.
public final class ReactionDeletedEvent: ChannelSpecificEvent {
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

    init(user: ChatUser, cid: ChannelId, message: ChatMessage, reaction: ChatMessageReaction, createdAt: Date) {
        self.user = user
        self.cid = cid
        self.message = message
        self.reaction = reaction
        self.createdAt = createdAt
    }
}

extension ReactionDeletedEventDTO: EventDTO {
    func toDomainEvent(session: any DatabaseSession) -> (any Event)? {
        guard let user = user, let message = message, let reaction = reaction else { return nil }
        guard let cidString = cid, let channelId = try? ChannelId(cid: cidString) else { return nil }
        guard
            let userDTO = session.user(id: user.id),
            let messageDTO = session.message(id: message.id),
            let reactionDTO = session.reaction(
                messageId: message.id,
                userId: user.id,
                type: MessageReactionType(rawValue: reaction.type)
            )
        else { return nil }

        return try? ReactionDeletedEvent(
            user: userDTO.asModel(),
            cid: channelId,
            message: messageDTO.asModel(),
            reaction: reactionDTO.asModel(),
            createdAt: createdAt
        )
    }
}

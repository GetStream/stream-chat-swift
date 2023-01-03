//
// Copyright © 2023 Stream.io Inc. All rights reserved.
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

class ReactionNewEventDTO: EventDTO {
    let user: UserPayload
    let cid: ChannelId
    let message: MessagePayload
    let reaction: MessageReactionPayload
    let createdAt: Date
    let payload: EventPayload

    init(from response: EventPayload) throws {
        user = try response.value(at: \.user)
        cid = try response.value(at: \.cid)
        message = try response.value(at: \.message)
        reaction = try response.value(at: \.reaction)
        createdAt = try response.value(at: \.createdAt)
        payload = response
    }

    func toDomainEvent(session: DatabaseSession) -> Event? {
        guard
            let userDTO = session.user(id: user.id),
            let messageDTO = session.message(id: message.id),
            let reactionDTO = session.reaction(
                messageId: message.id,
                userId: user.id,
                type: reaction.type
            )
        else { return nil }

        return try? ReactionNewEvent(
            user: userDTO.asModel(),
            cid: cid,
            message: messageDTO.asModel(),
            reaction: reactionDTO.asModel(),
            createdAt: createdAt
        )
    }
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

class ReactionUpdatedEventDTO: EventDTO {
    let user: UserPayload
    let cid: ChannelId
    let message: MessagePayload
    let reaction: MessageReactionPayload
    let createdAt: Date
    let payload: EventPayload

    init(from response: EventPayload) throws {
        user = try response.value(at: \.user)
        cid = try response.value(at: \.cid)
        message = try response.value(at: \.message)
        reaction = try response.value(at: \.reaction)
        createdAt = try response.value(at: \.createdAt)
        payload = response
    }

    func toDomainEvent(session: DatabaseSession) -> Event? {
        guard
            let userDTO = session.user(id: user.id),
            let messageDTO = session.message(id: message.id),
            let reactionDTO = session.reaction(
                messageId: message.id,
                userId: user.id,
                type: reaction.type
            )
        else { return nil }

        return try? ReactionUpdatedEvent(
            user: userDTO.asModel(),
            cid: cid,
            message: messageDTO.asModel(),
            reaction: reactionDTO.asModel(),
            createdAt: createdAt
        )
    }
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

class ReactionDeletedEventDTO: EventDTO {
    let user: UserPayload
    let cid: ChannelId
    let message: MessagePayload
    let reaction: MessageReactionPayload
    let createdAt: Date
    let payload: EventPayload

    init(from response: EventPayload) throws {
        user = try response.value(at: \.user)
        cid = try response.value(at: \.cid)
        message = try response.value(at: \.message)
        reaction = try response.value(at: \.reaction)
        createdAt = try response.value(at: \.createdAt)
        payload = response
    }

    func toDomainEvent(session: DatabaseSession) -> Event? {
        guard
            let userDTO = session.user(id: user.id),
            let messageDTO = session.message(id: message.id),
            let reactionDTO = session.reaction(
                messageId: message.id,
                userId: user.id,
                type: reaction.type
            )
        else { return nil }

        return try? ReactionDeletedEvent(
            user: userDTO.asModel(),
            cid: cid,
            message: messageDTO.asModel(),
            reaction: reactionDTO.asModel(),
            createdAt: createdAt
        )
    }
}

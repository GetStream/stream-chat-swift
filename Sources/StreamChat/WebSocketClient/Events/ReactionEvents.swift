//
// Copyright © 2021 Stream.io Inc. All rights reserved.
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

struct ReactionNewEventDTO: EventWithPayload {
    let user: UserPayload
    let cid: ChannelId
    let message: MessagePayload
    let reaction: MessageReactionPayload
    let createdAt: Date
    let payload: Any
    
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
        
        return ReactionNewEvent(
            user: userDTO.asModel(),
            cid: cid,
            message: messageDTO.asModel(),
            reaction: reactionDTO.asModel(),
            createdAt: createdAt
        )
    }
}

public struct ReactionUpdatedEvent: ReactionEvent {
    public let userId: UserId
    public let cid: ChannelId
    public let messageId: MessageId
    public let reactionType: MessageReactionType
    public let reactionScore: Int
    public let updatedAt: Date
    
    let payload: Any
    
    init(from response: EventPayload) throws {
        userId = try response.value(at: \.reaction?.user.id)
        cid = try response.value(at: \.cid)
        messageId = try response.value(at: \.reaction?.messageId)
        reactionType = try response.value(at: \.reaction?.type)
        reactionScore = try response.value(at: \.reaction?.score)
        updatedAt = try response.value(at: \.reaction?.updatedAt)
        payload = response
    }
}

public struct ReactionDeletedEvent: ReactionEvent {
    public let userId: UserId
    public let cid: ChannelId
    public let messageId: MessageId
    public let reactionType: MessageReactionType
    public let reactionScore: Int
    
    let payload: Any
    
    init(from response: EventPayload) throws {
        userId = try response.value(at: \.reaction?.user.id)
        cid = try response.value(at: \.cid)
        messageId = try response.value(at: \.reaction?.messageId)
        reactionType = try response.value(at: \.reaction?.type)
        reactionScore = try response.value(at: \.reaction?.score)
        payload = response
    }
}

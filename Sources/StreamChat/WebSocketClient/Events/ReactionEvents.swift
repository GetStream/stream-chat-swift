//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

public struct ReactionNewEvent: EventWithReactionPayload {
    public let userId: UserId
    public let cid: ChannelId
    public let messageId: MessageId
    public let reactionType: MessageReactionType
    public let reactionScore: Int
    public let createdAt: Date
    
    let payload: Any
    
    init<ExtraData: ExtraDataTypes>(from response: EventPayload<ExtraData>) throws {
        userId = try response.value(at: \.reaction?.user.id)
        cid = try response.value(at: \.cid)
        messageId = try response.value(at: \.reaction?.messageId)
        reactionType = try response.value(at: \.reaction?.type)
        reactionScore = try response.value(at: \.reaction?.score)
        createdAt = try response.value(at: \.reaction?.createdAt)
        payload = response
    }
}

public struct ReactionUpdatedEvent: EventWithReactionPayload {
    public let userId: UserId
    public let cid: ChannelId
    public let messageId: MessageId
    public let reactionType: MessageReactionType
    public let reactionScore: Int
    public let updatedAt: Date
    
    let payload: Any
    
    init<ExtraData: ExtraDataTypes>(from response: EventPayload<ExtraData>) throws {
        userId = try response.value(at: \.reaction?.user.id)
        cid = try response.value(at: \.cid)
        messageId = try response.value(at: \.reaction?.messageId)
        reactionType = try response.value(at: \.reaction?.type)
        reactionScore = try response.value(at: \.reaction?.score)
        updatedAt = try response.value(at: \.reaction?.updatedAt)
        payload = response
    }
}

public struct ReactionDeletedEvent: EventWithReactionPayload {
    public let userId: UserId
    public let cid: ChannelId
    public let messageId: MessageId
    public let reactionType: MessageReactionType
    public let reactionScore: Int
    
    let payload: Any
    
    init<ExtraData: ExtraDataTypes>(from response: EventPayload<ExtraData>) throws {
        userId = try response.value(at: \.reaction?.user.id)
        cid = try response.value(at: \.cid)
        messageId = try response.value(at: \.reaction?.messageId)
        reactionType = try response.value(at: \.reaction?.type)
        reactionScore = try response.value(at: \.reaction?.score)
        payload = response
    }
}

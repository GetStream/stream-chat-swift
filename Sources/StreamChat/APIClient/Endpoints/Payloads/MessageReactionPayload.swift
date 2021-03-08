//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// The type describes the incoming message-reaction JSON.
struct MessageReactionPayload<ExtraData: ExtraDataTypes>: Decodable {
    private enum CodingKeys: String, CodingKey {
        case type
        case score
        case messageId = "message_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case user
    }
    
    let type: MessageReactionType
    let score: Int
    let messageId: String
    let createdAt: Date
    let updatedAt: Date
    let user: UserPayload<ExtraData.User>
    let extraData: ExtraData.MessageReaction
    
    init(
        type: MessageReactionType,
        score: Int,
        messageId: String,
        createdAt: Date,
        updatedAt: Date,
        user: UserPayload<ExtraData.User>,
        extraData: ExtraData.MessageReaction
    ) {
        self.type = type
        self.score = score
        self.messageId = messageId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.user = user
        self.extraData = extraData
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            type: try container.decode(MessageReactionType.self, forKey: .type),
            score: try container.decode(Int.self, forKey: .score),
            messageId: try container.decode(MessageId.self, forKey: .messageId),
            createdAt: try container.decode(Date.self, forKey: .createdAt),
            updatedAt: try container.decode(Date.self, forKey: .updatedAt),
            user: try container.decode(UserPayload<ExtraData.User>.self, forKey: .user),
            extraData: try .init(from: decoder)
        )
    }
}

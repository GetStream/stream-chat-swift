//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// The type describes the incoming message-reaction JSON.
struct MessageReactionPayload: Decodable {
    private enum CodingKeys: String, CodingKey, CaseIterable {
        case type
        case score
        case messageId = "message_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case user
        case userId = "user_id"
    }
    
    let type: MessageReactionType
    let score: Int
    let messageId: String
    let createdAt: Date
    let updatedAt: Date
    let user: UserPayload
    let extraData: [String: RawJSON]

    init(
        type: MessageReactionType,
        score: Int,
        messageId: String,
        createdAt: Date,
        updatedAt: Date,
        user: UserPayload,
        extraData: [String: RawJSON]
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
        let extraData: [String: RawJSON]

        if var payload = try? [String: RawJSON](from: decoder) {
            payload.removeValues(forKeys: MessageReactionPayload.CodingKeys.allCases.map(\.rawValue))
            extraData = payload
        } else {
            extraData = [:]
        }
        
        self.init(
            type: try container.decode(MessageReactionType.self, forKey: .type),
            score: try container.decode(Int.self, forKey: .score),
            messageId: try container.decode(MessageId.self, forKey: .messageId),
            createdAt: try container.decode(Date.self, forKey: .createdAt),
            updatedAt: try container.decode(Date.self, forKey: .updatedAt),
            user: try container.decode(UserPayload.self, forKey: .user),
            extraData: extraData
        )
    }
}

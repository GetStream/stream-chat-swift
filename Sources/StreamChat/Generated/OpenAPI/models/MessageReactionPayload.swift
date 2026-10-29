//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class MessageReactionPayload: Sendable, Decodable {
    /// Date/time of creation
    let createdAt: Date
    /// Custom data for this object
    let custom: [String: RawJSON]
    /// Message ID
    let messageId: String
    /// Score of the reaction
    let score: Int
    /// Type of reaction
    let type: MessageReactionType
    /// Date/time of the last update
    let updatedAt: Date
    /// User response object
    let user: UserPayload
    /// User ID
    let userId: String

    init(
        createdAt: Date,
        custom: [String: RawJSON],
        messageId: String,
        score: Int,
        type: MessageReactionType,
        updatedAt: Date,
        user: UserPayload,
        userId: String
    ) {
        self.createdAt = createdAt
        self.custom = custom
        self.messageId = messageId
        self.score = score
        self.type = type
        self.updatedAt = updatedAt
        self.user = user
        self.userId = userId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        custom = try container.decodeIfPresent([String: RawJSON].self, forKey: .custom) ?? [:]
        messageId = try container.decode(String.self, forKey: .messageId)
        score = try container.decode(Int.self, forKey: .score)
        type = try container.decode(MessageReactionType.self, forKey: .type)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        user = try container.decode(UserPayload.self, forKey: .user)
        userId = try container.decode(String.self, forKey: .userId)
    }
}

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

    enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        case custom
        case messageId = "message_id"
        case score
        case type
        case updatedAt = "updated_at"
        case user
        case userId = "user_id"
    }
}

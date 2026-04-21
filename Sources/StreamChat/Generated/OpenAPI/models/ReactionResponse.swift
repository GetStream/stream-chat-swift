//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ReactionResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Date/time of creation
    var createdAt: Date
    /// Custom data for this object
    var custom: [String: RawJSON]
    /// Message ID
    var messageId: String
    /// Score of the reaction
    var score: Int
    /// Type of reaction
    var type: String
    /// Date/time of the last update
    var updatedAt: Date
    var user: UserResponse
    /// User ID
    var userId: String

    init(createdAt: Date, custom: [String: RawJSON], messageId: String, score: Int, type: String, updatedAt: Date, user: UserResponse, userId: String) {
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

    static func == (lhs: ReactionResponse, rhs: ReactionResponse) -> Bool {
        lhs.createdAt == rhs.createdAt &&
            lhs.custom == rhs.custom &&
            lhs.messageId == rhs.messageId &&
            lhs.score == rhs.score &&
            lhs.type == rhs.type &&
            lhs.updatedAt == rhs.updatedAt &&
            lhs.user == rhs.user &&
            lhs.userId == rhs.userId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(createdAt)
        hasher.combine(custom)
        hasher.combine(messageId)
        hasher.combine(score)
        hasher.combine(type)
        hasher.combine(updatedAt)
        hasher.combine(user)
        hasher.combine(userId)
    }
}

//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ChatReactionResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var createdAt: Date
    var custom: [String: RawJSON]
    var messageId: String
    var score: Int
    var type: String
    var updatedAt: Date
    var user: UserResponse
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

    static func == (lhs: ChatReactionResponse, rhs: ChatReactionResponse) -> Bool {
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

//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ChatReactionGroupUserResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var createdAt: Date
    var user: UserResponse?
    var userId: String

    init(createdAt: Date, user: UserResponse? = nil, userId: String) {
        self.createdAt = createdAt
        self.user = user
        self.userId = userId
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        case user
        case userId = "user_id"
    }

    static func == (lhs: ChatReactionGroupUserResponse, rhs: ChatReactionGroupUserResponse) -> Bool {
        lhs.createdAt == rhs.createdAt &&
            lhs.user == rhs.user &&
            lhs.userId == rhs.userId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(createdAt)
        hasher.combine(user)
        hasher.combine(userId)
    }
}

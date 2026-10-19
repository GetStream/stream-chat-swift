//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// An object describing the incoming blocking user JSON payload.
struct BlockingUserPayload: Decodable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case blockedUserId = "blocked_user_id"
        case blockedByUserId = "blocked_by_user_id"
        case createdAt = "created_at"
    }

    let blockedUserId: String
    let blockedByUserId: String
    let createdAt: Date
}

/// An object describing the incoming blocked users JSON payload.
struct BlocksPayload: Decodable {
    private enum CodingKeys: String, CodingKey {
        case blockedUsers = "blocks"
    }

    /// The blocked users.
    let blockedUsers: [BlockPayload]
}

/// An object describing the incoming block JSON payload.
struct BlockPayload: Decodable {
    private enum CodingKeys: String, CodingKey {
        case blockedUserId = "blocked_user_id"
        case userId = "user_id"
        case createdAt = "created_at"
        case blockedUser = "blocked_user"
    }

    let blockedUserId: String
    let userId: String
    let createdAt: Date
    let blockedUser: UserPayload
}

extension BlockPayload: Equatable {
    static func == (lhs: BlockPayload, rhs: BlockPayload) -> Bool {
        lhs.blockedUserId == rhs.blockedUserId
            && lhs.userId == rhs.userId
            && lhs.createdAt == rhs.createdAt
    }
}

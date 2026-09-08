//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class BlockedUserResponse: Sendable, Decodable {
    /// User response object
    let blockedUser: UserPayload
    /// ID of the user who got blocked
    let blockedUserId: String
    let createdAt: Date
    /// User response object
    let user: UserPayload
    /// ID of the user who blocked another user
    let userId: String

    init(
        blockedUser: UserPayload,
        blockedUserId: String,
        createdAt: Date,
        user: UserPayload,
        userId: String
    ) {
        self.blockedUser = blockedUser
        self.blockedUserId = blockedUserId
        self.createdAt = createdAt
        self.user = user
        self.userId = userId
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case blockedUser = "blocked_user"
        case blockedUserId = "blocked_user_id"
        case createdAt = "created_at"
        case user
        case userId = "user_id"
    }
}

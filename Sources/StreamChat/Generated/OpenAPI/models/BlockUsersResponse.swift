//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class BlockUsersResponse: Sendable, Decodable {
    /// User id who blocked another user
    let blockedByUserId: String
    /// User id who got blocked
    let blockedUserId: String
    /// Timestamp when the user was blocked
    let createdAt: Date

    init(blockedByUserId: String, blockedUserId: String, createdAt: Date) {
        self.blockedByUserId = blockedByUserId
        self.blockedUserId = blockedUserId
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case blockedByUserId = "blocked_by_user_id"
        case blockedUserId = "blocked_user_id"
        case createdAt = "created_at"
    }
}

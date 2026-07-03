//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class BlockedUserResponse: Sendable, Codable, JSONEncodable {
    /// ID of the user who got blocked
    let blockedUserId: String
    let createdAt: Date

    init(blockedUserId: String, createdAt: Date) {
        self.blockedUserId = blockedUserId
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case blockedUserId = "blocked_user_id"
        case createdAt = "created_at"
    }
}

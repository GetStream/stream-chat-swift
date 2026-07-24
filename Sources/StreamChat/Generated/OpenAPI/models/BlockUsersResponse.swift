//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

final class BlockUsersResponse: Sendable, Codable, JSONEncodable {
    /// User id who blocked another user
    let blockedByUserId: String
    /// User id who got blocked
    let blockedUserId: String
    /// Timestamp when the user was blocked
    let createdAt: Date
    /// Duration of the request in milliseconds
    let duration: String

    init(
        blockedByUserId: String,
        blockedUserId: String,
        createdAt: Date,
        duration: String
    ) {
        self.blockedByUserId = blockedByUserId
        self.blockedUserId = blockedUserId
        self.createdAt = createdAt
        self.duration = duration
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case blockedByUserId = "blocked_by_user_id"
        case blockedUserId = "blocked_user_id"
        case createdAt = "created_at"
        case duration
    }
}

//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class BlockUsersResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// User id who blocked another user
    var blockedByUserId: String
    /// User id who got blocked
    var blockedUserId: String
    /// Timestamp when the user was blocked
    var createdAt: Date
    /// Duration of the request in milliseconds
    var duration: String

    init(blockedByUserId: String, blockedUserId: String, createdAt: Date, duration: String) {
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

    static func == (lhs: BlockUsersResponse, rhs: BlockUsersResponse) -> Bool {
        lhs.blockedByUserId == rhs.blockedByUserId &&
            lhs.blockedUserId == rhs.blockedUserId &&
            lhs.createdAt == rhs.createdAt &&
            lhs.duration == rhs.duration
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(blockedByUserId)
        hasher.combine(blockedUserId)
        hasher.combine(createdAt)
        hasher.combine(duration)
    }
}

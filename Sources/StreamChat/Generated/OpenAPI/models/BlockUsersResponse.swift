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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.blockedByUserId = try container.decode(String.self, forKey: .blockedByUserId)
        self.blockedUserId = try container.decode(String.self, forKey: .blockedUserId)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
}

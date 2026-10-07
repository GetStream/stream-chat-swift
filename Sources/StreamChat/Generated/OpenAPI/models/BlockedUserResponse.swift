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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.blockedUser = try container.decode(UserPayload.self, forKey: .blockedUser)
        self.blockedUserId = try container.decode(String.self, forKey: .blockedUserId)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.user = try container.decode(UserPayload.self, forKey: .user)
        self.userId = try container.decode(String.self, forKey: .userId)
    }
}

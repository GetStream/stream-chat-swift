//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A type representing a blocked user.
public struct BlockedUserDetails: Sendable {
    /// The unique identifier of the blocked user.
    public let userId: UserId

    /// The date the user was blocked.
    public let blockedAt: Date?

    /// The blocked user.
    public let blockedUser: ChatUser?

    init(
        userId: UserId,
        blockedAt: Date?,
        blockedUser: ChatUser?
    ) {
        self.userId = userId
        self.blockedAt = blockedAt
        self.blockedUser = blockedUser
    }
}

extension BlockedUserDetails: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(userId)
    }
}

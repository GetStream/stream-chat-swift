//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// A type representing a blocked user.
public struct BlockedUserDetails {
    /// The unique identifier of the blocked user.
    public let userId: UserId

    /// The date the user was blocked.
    public let blockedAt: Date?

    init(
        userId: UserId,
        blockedAt: Date?
    ) {
        self.userId = userId
        self.blockedAt = blockedAt
    }
}

extension BlockedUserDetails: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(userId)
    }
}

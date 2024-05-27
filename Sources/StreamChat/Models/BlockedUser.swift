//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// A type representing a blocked user. `BlockedUser` is an immutable snapshot of a blocked user entity at the given time.
///
public struct BlockedUser {
    /// The unique identifier of the blocked user.
    public let blockedUserId: UserId

    /// The date the user was blocked.
    public let blockedAt: Date?

    init(
        blockedUserId: UserId,
        blockedAt: Date?
    ) {
        self.blockedUserId = blockedUserId
        self.blockedAt = blockedAt
    }
}

extension BlockedUser: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(blockedUserId)
    }
}

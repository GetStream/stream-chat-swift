//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension MutedUserPayload {
    /// Returns a muted user with the given `userId` and `extraData`
    static func dummy(
        userId: UserId,
        extraData: ExtraData = .defaultValue
    ) -> Self {
        .init(
            mutedUser: .init(
                id: userId,
                role: .user,
                createdAt: .unique,
                updatedAt: .unique,
                lastActiveAt: .unique,
                isOnline: true,
                isInvisible: true,
                isBanned: true,
                teams: [],
                extraData: extraData
            ),
            created: .unique,
            updated: .unique
        )
    }
}

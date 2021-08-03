//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension MutedUserPayload {
    /// Returns a muted user with the given `userId` and `extraData`
    static func dummy(
        userId: UserId,
        extraData: [String: RawJSON] = [:]
    ) -> Self {
        .init(
            mutedUser: .init(
                id: userId,
                name: .unique,
                imageURL: .unique(),
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

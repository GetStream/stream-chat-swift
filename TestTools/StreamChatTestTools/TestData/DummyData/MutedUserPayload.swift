//
// Copyright © 2025 Stream.io Inc. All rights reserved.
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
                teamsRole: nil,
                createdAt: .unique,
                updatedAt: .unique,
                deactivatedAt: nil,
                lastActiveAt: .unique,
                isOnline: true,
                isInvisible: true,
                isBanned: true,
                teams: [],
                language: nil,
                extraData: extraData
            ),
            created: .unique,
            updated: .unique
        )
    }
}

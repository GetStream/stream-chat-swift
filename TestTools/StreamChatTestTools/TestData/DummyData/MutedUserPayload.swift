//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import StreamCore

extension MutedUserPayload {
    /// Returns a muted user with the given `userId` and `extraData`
    static func dummy(
        userId: UserId,
        extraData: [String: RawJSON] = [:]
    ) -> MutedUserPayload {
        .init(
            createdAt: .unique,
            target: .init(
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
                isBanned: true,
                teams: [],
                language: nil,
                extraData: extraData
            ),
            updatedAt: .unique
        )
    }
}

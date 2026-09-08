//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension MutedUserPayload {
    /// Returns a muted user with the given `userId` and `extraData`
    static func dummy(
        userId: UserId,
        extraData: [String: RawJSON] = [:]
    ) -> MutedUserPayload {
        .init(
            createdAt: .unique,
            target: .dummy(userId: userId, role: .user, extraData: extraData, teams: [], isBanned: true),
            updatedAt: .unique
        )
    }
}

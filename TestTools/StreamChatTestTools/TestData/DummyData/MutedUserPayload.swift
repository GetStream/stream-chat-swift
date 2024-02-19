//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension UserMute {
    /// Returns a muted user with the given `userId` and `extraData`
    static func dummy(
        userId: UserId,
        extraData: [String: RawJSON] = [:]
    ) -> Self {
        UserMute(
            createdAt: .unique,
            updatedAt: .unique,
            expires: .unique,
            target: .dummy(userId: userId)
        )
    }
}

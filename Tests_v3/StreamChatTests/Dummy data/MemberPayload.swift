//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension MemberPayload where ExtraData == NoExtraData.User {
    /// Returns a dummy member payload with the given `userId` and `role`
    static func dummy(
        userId: UserId = .unique,
        createdAt: Date = .unique,
        updatedAt: Date = .unique,
        role: MemberRole = .member
    ) -> MemberPayload {
        .init(
            user: .dummy(userId: userId),
            role: role,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

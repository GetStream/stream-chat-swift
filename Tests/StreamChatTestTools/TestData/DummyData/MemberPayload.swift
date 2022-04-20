//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension MemberPayload {
    /// Returns a dummy member payload with the given `userId` and `role`
    static func dummy(
        user: UserPayload = .dummy(userId: .unique),
        createdAt: Date = .unique,
        updatedAt: Date = .unique,
        role: MemberRole = .member,
        isMemberBanned: Bool = false
    ) -> MemberPayload {
        .init(
            user: user,
            role: role,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isBanned: isMemberBanned
        )
    }
}

extension MemberContainerPayload {
    static func dummy(userId: UserId = .unique) -> MemberContainerPayload {
        .init(
            member: .dummy(user: .dummy(userId: userId)),
            invite: nil,
            memberRole: nil
        )
    }
}

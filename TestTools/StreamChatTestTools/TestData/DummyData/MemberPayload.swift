//
// Copyright © 2025 Stream.io Inc. All rights reserved.
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
        isMemberBanned: Bool = false,
        archivedAt: Date? = nil,
        pinnedAt: Date? = nil
    ) -> MemberPayload {
        .init(
            user: user,
            userId: user.id,
            role: role,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isBanned: isMemberBanned,
            archivedAt: archivedAt,
            pinnedAt: pinnedAt
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

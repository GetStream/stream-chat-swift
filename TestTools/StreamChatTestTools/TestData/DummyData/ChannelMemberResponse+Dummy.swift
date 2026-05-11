//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension ChannelMemberResponse {
    /// Returns a dummy member payload with the given `userId` and `role`
    static func dummy(
        user: UserResponse = .dummy(userId: .unique),
        createdAt: Date = .unique,
        updatedAt: Date = .unique,
        role: MemberRole = .member,
        isMemberBanned: Bool = false,
        archivedAt: Date? = nil,
        pinnedAt: Date? = nil
    ) -> ChannelMemberResponse {
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

extension ChannelMemberResponse {
    static func dummy(userId: UserId = .unique) -> ChannelMemberResponse {
        .init(
            member: .dummy(user: UserResponse.dummy(userId: userId)),
            invite: nil,
            memberRole: nil
        )
    }
}

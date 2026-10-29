//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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
        status: String? = nil,
        deletedAt: Date? = nil,
        isMemberBanned: Bool = false,
        archivedAt: Date? = nil,
        pinnedAt: Date? = nil,
        notificationsMuted: Bool = false,
        extraData: [String: RawJSON] = [:]
    ) -> MemberPayload {
        .init(
            user: user,
            userId: user.id,
            role: role,
            status: status,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            isBanned: isMemberBanned,
            archivedAt: archivedAt,
            pinnedAt: pinnedAt,
            notificationsMuted: notificationsMuted,
            extraData: extraData
        )
    }
}

extension MembersResponse {
    static func dummy(members: [MemberPayload] = []) -> MembersResponse {
        .init(members: members)
    }
}

extension UpdateMemberPartialResponse {
    static func dummy(channelMember: MemberPayload? = nil) -> UpdateMemberPartialResponse {
        .init(channelMember: channelMember)
    }
}

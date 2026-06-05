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
        banExpiresAt: Date? = nil,
        isShadowBanned: Bool = false,
        archivedAt: Date? = nil,
        pinnedAt: Date? = nil,
        notificationsMuted: Bool = false,
        extraData: [String: RawJSON] = [:]
    ) -> ChannelMemberResponse {
        .init(
            archivedAt: archivedAt,
            banExpires: banExpiresAt,
            banned: isMemberBanned,
            channelRole: role.rawChannelValue,
            createdAt: createdAt,
            custom: extraData,
            inviteAcceptedAt: nil,
            inviteRejectedAt: nil,
            invited: nil,
            notificationsMuted: notificationsMuted,
            pinnedAt: pinnedAt,
            role: role.rawValue,
            shadowBanned: isShadowBanned,
            updatedAt: updatedAt,
            user: user,
            userId: user.id
        )
    }
}

extension ChannelMemberResponse {
    static func dummy(userId: UserId = .unique) -> ChannelMemberResponse {
        .dummy(user: UserResponse.dummy(userId: userId))
    }
}

extension MembersResponse {
    static func dummy(
        duration: String = "",
        members: [ChannelMemberResponse] = []
    ) -> MembersResponse {
        .init(duration: duration, members: members)
    }
}

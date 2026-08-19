//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

// Generated properties are slightly different from the previously hand-written ones.
extension MemberPayload {
    // `user_id` is omitted when the nested `user` object carries the id.
    var memberId: String? { userId ?? user?.id }

    convenience init(
        user: UserPayload?,
        userId: String?,
        role: MemberRole?,
        status: String? = nil,
        createdAt: Date,
        updatedAt: Date,
        deletedAt: Date? = nil,
        banExpiresAt: Date? = nil,
        isBanned: Bool? = nil,
        isShadowBanned: Bool? = nil,
        isInvited: Bool? = nil,
        inviteAcceptedAt: Date? = nil,
        inviteRejectedAt: Date? = nil,
        archivedAt: Date? = nil,
        pinnedAt: Date? = nil,
        notificationsMuted: Bool = false,
        extraData: [String: RawJSON] = [:]
    ) {
        self.init(
            archivedAt: archivedAt,
            banExpires: banExpiresAt,
            banned: isBanned,
            channelRole: role?.rawChannelValue,
            createdAt: createdAt,
            custom: extraData,
            deletedAt: deletedAt,
            inviteAcceptedAt: inviteAcceptedAt,
            inviteRejectedAt: inviteRejectedAt,
            invited: isInvited,
            notificationsMuted: notificationsMuted,
            pinnedAt: pinnedAt,
            shadowBanned: isShadowBanned,
            status: status,
            updatedAt: updatedAt,
            user: user,
            userId: userId
        )
    }
}

//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

public extension _ChatChannelMember {
    /// Creates a new `_ChatChannelMember` object from the provided data.
    static func mock(
        id: String,
        isOnline: Bool,
        isBanned: Bool,
        userRole: UserRole,
        userCreatedAt: Date,
        userUpdatedAt: Date,
        lastActiveAt: Date?,
        extraData: ExtraData,
        memberRole: MemberRole,
        memberCreatedAt: Date,
        memberUpdatedAt: Date,
        isInvited: Bool,
        inviteAcceptedAt: Date?,
        inviteRejectedAt: Date?
    ) -> _ChatChannelMember {
        .init(
            id: id,
            isOnline: isOnline,
            isBanned: isBanned,
            userRole: userRole,
            userCreatedAt: userCreatedAt,
            userUpdatedAt: userUpdatedAt,
            lastActiveAt: lastActiveAt,
            extraData: extraData,
            memberRole: memberRole,
            memberCreatedAt: memberCreatedAt,
            memberUpdatedAt: memberUpdatedAt,
            isInvited: isInvited,
            inviteAcceptedAt: inviteAcceptedAt,
            inviteRejectedAt: inviteRejectedAt
        )
    }
}

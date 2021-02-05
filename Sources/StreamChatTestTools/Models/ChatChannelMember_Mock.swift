//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

public extension _ChatChannelMember {
    /// Creates a new `_ChatChannelMember` object from the provided data.
    static func mock(
        id: String,
        name: String? = nil,
        imageURL: URL? = nil,
        isOnline: Bool = false,
        isBanned: Bool = false,
        userRole: UserRole = .user,
        userCreatedAt: Date = .distantPast,
        userUpdatedAt: Date = .distantPast,
        lastActiveAt: Date? = nil,
        extraData: ExtraData = .defaultValue,
        memberRole: MemberRole = .member,
        memberCreatedAt: Date = .distantPast,
        memberUpdatedAt: Date = .distantPast,
        isInvited: Bool = false,
        inviteAcceptedAt: Date? = nil,
        inviteRejectedAt: Date? = nil
    ) -> _ChatChannelMember {
        .init(
            id: id,
            name: name,
            imageURL: imageURL,
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

//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension ChatChannelMember {
    static var dummy: ChatChannelMember {
        .init(
            id: .unique,
            name: .unique,
            imageURL: .unique(),
            isOnline: true,
            isBanned: false,
            isFlaggedByCurrentUser: false,
            userRole: .user,
            userCreatedAt: .unique,
            userUpdatedAt: .unique,
            lastActiveAt: .unique,
            teams: [],
            extraData: [:],
            memberRole: .member,
            memberCreatedAt: .unique,
            memberUpdatedAt: .unique,
            isInvited: true,
            inviteAcceptedAt: .unique,
            inviteRejectedAt: nil,
            isBannedFromChannel: true,
            banExpiresAt: .unique,
            isShadowBannedFromChannel: true
        )
    }
}

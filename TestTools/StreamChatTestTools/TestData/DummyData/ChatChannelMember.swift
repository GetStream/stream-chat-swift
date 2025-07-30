//
// Copyright © 2025 Stream.io Inc. All rights reserved.
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
            teamsRole: nil,
            userCreatedAt: .unique,
            userUpdatedAt: .unique,
            deactivatedAt: nil,
            lastActiveAt: .unique,
            teams: [],
            language: nil,
            extraData: [:],
            memberRole: .member,
            memberCreatedAt: .unique,
            memberUpdatedAt: .unique,
            isInvited: true,
            inviteAcceptedAt: .unique,
            inviteRejectedAt: nil,
            archivedAt: nil,
            pinnedAt: nil,
            isBannedFromChannel: true,
            banExpiresAt: .unique,
            isShadowBannedFromChannel: true, 
            notificationsMuted: false,
            avgResponseTime: nil,
            memberExtraData: [:]
        )
    }
}

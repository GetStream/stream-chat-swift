//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

public extension ChatChannelMember {
    /// Creates a new `ChatChannelMember` object from the provided data.
    static func mock(
        id: String,
        name: String? = nil,
        imageURL: URL? = nil,
        isOnline: Bool = false,
        isBanned: Bool = false,
        isFlaggedByCurrentUser: Bool = false,
        userRole: UserRole = .user,
        userCreatedAt: Date = .distantPast,
        userUpdatedAt: Date = .distantPast,
        userDeactivatedAt: Date? = nil,
        lastActiveAt: Date? = nil,
        teams: Set<TeamId> = ["RED", "GREEN"],
        language: TranslationLanguage? = nil,
        extraData: [String: RawJSON] = [:],
        memberRole: MemberRole = .member,
        memberCreatedAt: Date = .distantPast,
        memberUpdatedAt: Date = .distantPast,
        isInvited: Bool = false,
        inviteAcceptedAt: Date? = nil,
        inviteRejectedAt: Date? = nil,
        isBannedFromChannel: Bool = false,
        banExpiresAt: Date? = nil,
        isShadowBannedFromChannel: Bool = false,
        notificationsMuted: Bool = false
    ) -> ChatChannelMember {
        .init(
            id: id,
            name: name,
            imageURL: imageURL,
            isOnline: isOnline,
            isBanned: isBanned,
            isFlaggedByCurrentUser: isFlaggedByCurrentUser,
            userRole: userRole,
            userCreatedAt: userCreatedAt,
            userUpdatedAt: userUpdatedAt,
            deactivatedAt: userDeactivatedAt,
            lastActiveAt: lastActiveAt,
            teams: teams,
            language: language,
            extraData: extraData,
            memberRole: memberRole,
            memberCreatedAt: memberCreatedAt,
            memberUpdatedAt: memberUpdatedAt,
            isInvited: isInvited,
            inviteAcceptedAt: inviteAcceptedAt,
            inviteRejectedAt: inviteRejectedAt,
            isBannedFromChannel: isBannedFromChannel,
            banExpiresAt: banExpiresAt,
            isShadowBannedFromChannel: isShadowBannedFromChannel,
            notificationsMuted: notificationsMuted
        )
    }
}

//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension UserMuteResponse {
    /// Returns a muted user with the given `userId` and `extraData`
    static func dummy(
        userId: UserId,
        extraData: [String: RawJSON] = [:]
    ) -> Self {
        .init(
            createdAt: .unique,
            target: .init(
                id: userId,
                name: .unique,
                imageURL: .unique(),
                role: .user,
                teamsRole: nil,
                createdAt: .unique,
                updatedAt: .unique,
                deactivatedAt: nil,
                lastActiveAt: .unique,
                isOnline: true,
                isInvisible: true,
                isBanned: true,
                teams: [],
                language: nil,
                extraData: extraData
            ),
            updatedAt: .unique
        )
    }
}

extension ChannelMute {
    static func dummy(
        channel: ChannelResponse = .dummy(),
        createdAt: Date = .unique,
        expires: Date? = nil,
        updatedAt: Date = .unique,
        user: UserResponse = .dummy(userId: .unique)
    ) -> ChannelMute {
        .init(
            channel: channel,
            createdAt: createdAt,
            expires: expires,
            updatedAt: updatedAt,
            user: user
        )
    }
}

extension MuteChannelResponse {
    static func dummy(
        channelMute: ChannelMute,
        channelMutes: [ChannelMute]? = nil,
        duration: String = "",
        ownUser: OwnUserResponse? = nil
    ) -> MuteChannelResponse {
        .init(
            channelMute: channelMute,
            channelMutes: channelMutes,
            duration: duration,
            ownUser: ownUser
        )
    }
}

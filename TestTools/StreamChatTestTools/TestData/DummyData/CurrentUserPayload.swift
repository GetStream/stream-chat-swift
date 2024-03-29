//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension OwnUser {
    /// Returns a dummy current user payload with the given UserId and extra data
    static func dummy(
        userId: UserId,
        name: String = .unique,
        imageURL: URL? = nil,
        createdAt: Date = .unique,
        updatedAt: Date = .unique,
        deactivatedAt: Date? = nil,
        lastActiveAt: Date = .unique,
        isOnline: Bool = true,
        isInvisible: Bool = true,
        isBanned: Bool = true,
        role: UserRole,
        unreadCount: UnreadCount? = .dummy,
        extraData: [String: RawJSON] = [:],
        devices: [Device] = [],
        mutedUsers: [UserMute] = [],
        teams: [TeamId] = [],
        language: String? = nil,
        mutedChannels: [ChannelMute] = []
    ) -> OwnUser {
        OwnUser(
            banned: isBanned,
            createdAt: createdAt,
            id: userId,
            language: language ?? "en",
            online: isOnline,
            role: role.rawValue,
            totalUnreadCount: unreadCount?.messages ?? 0,
            unreadChannels: unreadCount?.channels ?? 0,
            unreadCount: unreadCount?.channels ?? 0,
            unreadThreads: 0,
            updatedAt: updatedAt,
            channelMutes: mutedChannels,
            devices: devices,
            mutes: mutedUsers,
            custom: extraData,
            deactivatedAt: deactivatedAt,
            deletedAt: nil,
            invisible: isInvisible,
            lastActive: lastActiveAt,
            latestHiddenChannels: nil,
            teams: teams,
            pushNotifications: nil
        )
    }
}

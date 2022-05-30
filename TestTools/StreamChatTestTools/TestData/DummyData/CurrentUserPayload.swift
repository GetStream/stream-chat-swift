//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension CurrentUserPayload {
    /// Returns a dummy current user payload with the given UserId and extra data
    static func dummy(
        userId: UserId,
        name: String = .unique,
        imageURL: URL? = nil,
        createdAt: Date = .unique,
        updatedAt: Date = .unique,
        lastActiveAt: Date = .unique,
        isOnline: Bool = true,
        isInvisible: Bool = true,
        isBanned: Bool = true,
        role: UserRole,
        unreadCount: UnreadCount? = .dummy,
        extraData: [String: RawJSON] = [:],
        devices: [DevicePayload] = [],
        mutedUsers: [MutedUserPayload] = [],
        teams: [TeamId] = [],
        mutedChannels: [MutedChannelPayload] = []
    ) -> CurrentUserPayload {
        .init(
            id: userId,
            name: name,
            imageURL: imageURL,
            role: role,
            createdAt: createdAt,
            updatedAt: updatedAt,
            lastActiveAt: lastActiveAt,
            isOnline: isOnline,
            isInvisible: isInvisible,
            isBanned: isBanned,
            teams: teams,
            extraData: extraData,
            devices: devices,
            mutedUsers: mutedUsers,
            mutedChannels: mutedChannels,
            unreadCount: unreadCount
        )
    }

    /// Returns a dummy current user payload with the given user payload
    static func dummy(
        userPayload: UserPayload,
        unreadCount: UnreadCount? = .dummy,
        devices: [DevicePayload] = [],
        mutedUsers: [MutedUserPayload] = [],
        mutedChannels: [MutedChannelPayload] = []
    ) -> CurrentUserPayload {
        .init(
            id: userPayload.id,
            name: userPayload.name,
            imageURL: userPayload.imageURL,
            role: userPayload.role,
            createdAt: userPayload.createdAt,
            updatedAt: userPayload.updatedAt,
            lastActiveAt: userPayload.lastActiveAt,
            isOnline: userPayload.isOnline,
            isInvisible: userPayload.isInvisible,
            isBanned: userPayload.isBanned,
            teams: userPayload.teams,
            extraData: userPayload.extraData,
            devices: devices,
            mutedUsers: mutedUsers,
            mutedChannels: mutedChannels,
            unreadCount: unreadCount
        )
    }
}

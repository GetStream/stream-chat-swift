//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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
        deactivatedAt: Date? = nil,
        lastActiveAt: Date = .unique,
        isOnline: Bool = true,
        isInvisible: Bool = true,
        isBanned: Bool = true,
        role: UserRole,
        teamsRole: [String: UserRole]? = nil,
        unreadCount: UnreadCountPayload? = .dummy,
        extraData: [String: RawJSON] = [:],
        devices: [DevicePayload] = [],
        mutedUsers: [MutedUserPayload] = [],
        teams: [TeamId] = [],
        language: String? = nil,
        mutedChannels: [MutedChannelPayload] = [],
        pushPreference: PushPreferencePayload? = nil
    ) -> CurrentUserPayload {
        .init(
            id: userId,
            name: name,
            imageURL: imageURL,
            role: role,
            teamsRole: teamsRole,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deactivatedAt: deactivatedAt,
            lastActiveAt: lastActiveAt,
            isOnline: isOnline,
            isInvisible: isInvisible,
            isBanned: isBanned,
            teams: teams,
            language: language,
            extraData: extraData,
            devices: devices,
            mutedUsers: mutedUsers,
            mutedChannels: mutedChannels,
            unreadCount: unreadCount,
            pushPreference: pushPreference
        )
    }

    /// Returns a dummy current user payload with the given user payload
    static func dummy(
        userPayload: UserPayload,
        unreadCount: UnreadCountPayload? = .dummy,
        devices: [DevicePayload] = [],
        mutedUsers: [MutedUserPayload] = [],
        mutedChannels: [MutedChannelPayload] = [],
        privacySettings: UserPrivacySettingsPayload? = nil,
        pushPreference: PushPreferencePayload? = nil
    ) -> CurrentUserPayload {
        .init(
            id: userPayload.id,
            name: userPayload.name,
            imageURL: userPayload.imageURL,
            role: userPayload.role,
            teamsRole: userPayload.teamsRole,
            createdAt: userPayload.createdAt,
            updatedAt: userPayload.updatedAt,
            deactivatedAt: userPayload.deactivatedAt,
            lastActiveAt: userPayload.lastActiveAt,
            isOnline: userPayload.isOnline,
            isInvisible: userPayload.isInvisible,
            isBanned: userPayload.isBanned,
            teams: userPayload.teams,
            language: userPayload.language,
            extraData: userPayload.extraData,
            devices: devices,
            mutedUsers: mutedUsers,
            mutedChannels: mutedChannels,
            unreadCount: unreadCount,
            privacySettings: privacySettings,
            pushPreference: pushPreference
        )
    }
}

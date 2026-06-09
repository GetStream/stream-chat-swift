//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension OwnUserResponse {
    /// Returns a dummy current user payload with the given UserId and extra data
    static func dummy(
        userId: UserId,
        name: String? = .unique,
        imageURL: URL? = nil,
        createdAt: Date = .unique,
        updatedAt: Date = .unique,
        deactivatedAt: Date? = nil,
        lastActiveAt: Date? = .unique,
        isOnline: Bool = true,
        isInvisible: Bool = true,
        isBanned: Bool = true,
        role: UserRole,
        teamsRole: [String: UserRole]? = nil,
        unreadCount: UnreadCountPayload? = .dummy,
        extraData: [String: RawJSON] = [:],
        devices: [DeviceResponse] = [],
        mutedUsers: [UserMuteResponse] = [],
        teams: [TeamId] = [],
        language: String? = nil,
        mutedChannels: [ChannelMute] = [],
        privacySettings: UserPrivacySettingsPayload? = nil,
        pushPreference: PushPreferencesResponse? = nil
    ) -> OwnUserResponse {
        OwnUserResponse(
            avgResponseTime: nil,
            banned: isBanned,
            blockedUserIds: [],
            channelMutes: mutedChannels,
            createdAt: createdAt,
            custom: extraData,
            deactivatedAt: deactivatedAt,
            devices: devices,
            id: userId,
            image: imageURL?.absoluteString,
            invisible: isInvisible,
            language: language ?? "",
            lastActive: lastActiveAt,
            mutes: mutedUsers,
            name: name,
            online: isOnline,
            privacySettings: privacySettings?.asPrivacySettingsResponse,
            pushPreferences: pushPreference,
            role: role.rawValue,
            teams: teams,
            teamsRole: teamsRole?.mapValues(\.rawValue),
            totalUnreadCount: unreadCount?.messages ?? 0,
            unreadChannels: unreadCount?.channels ?? 0,
            unreadCount: unreadCount?.messages ?? 0,
            unreadThreads: unreadCount?.threads ?? -1,
            updatedAt: updatedAt
        )
    }

    /// Returns a dummy current user payload with the given user payload
    static func dummy(
        userPayload: UserResponse,
        unreadCount: UnreadCountPayload? = .dummy,
        devices: [DeviceResponse] = [],
        mutedUsers: [UserMuteResponse] = [],
        mutedChannels: [ChannelMute] = [],
        privacySettings: UserPrivacySettingsPayload? = nil,
        pushPreference: PushPreferencesResponse? = nil
    ) -> OwnUserResponse {
        .dummy(
            userId: userPayload.id,
            name: userPayload.name,
            imageURL: userPayload.imageURL,
            createdAt: userPayload.createdAt,
            updatedAt: userPayload.updatedAt,
            deactivatedAt: userPayload.deactivatedAt,
            lastActiveAt: userPayload.lastActive,
            isOnline: userPayload.online,
            isInvisible: false,
            isBanned: userPayload.banned,
            role: userPayload.userRole,
            teamsRole: userPayload.teamsUserRole,
            unreadCount: unreadCount,
            extraData: userPayload.custom,
            devices: devices,
            mutedUsers: mutedUsers,
            teams: userPayload.teams,
            language: userPayload.language.isEmpty ? nil : userPayload.language,
            mutedChannels: mutedChannels,
            privacySettings: privacySettings,
            pushPreference: pushPreference
        )
    }
}

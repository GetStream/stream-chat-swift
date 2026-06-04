//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension OwnUserResponse {
    var asUserResponse: UserResponse {
        UserResponse(
            avgResponseTime: avgResponseTime,
            banned: banned,
            blockedUserIds: blockedUserIds ?? [],
            createdAt: createdAt,
            custom: custom,
            deactivatedAt: deactivatedAt,
            deletedAt: deletedAt,
            id: id,
            image: image,
            language: language,
            lastActive: lastActive,
            name: name,
            online: online,
            revokeTokensIssuedBefore: revokeTokensIssuedBefore,
            role: role,
            teams: teams,
            teamsRole: teamsRole,
            updatedAt: updatedAt
        )
    }

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
        devices: [DeviceResponse] = [],
        mutedUsers: [UserMuteResponse] = [],
        teams: [TeamId] = [],
        language: String? = nil,
        mutedChannels: [ChannelMute] = [],
        pushPreference: PushPreferencesResponse? = nil
    ) -> OwnUserResponse {
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
        userPayload: UserResponse,
        unreadCount: UnreadCountPayload? = .dummy,
        devices: [DeviceResponse] = [],
        mutedUsers: [UserMuteResponse] = [],
        mutedChannels: [ChannelMute] = [],
        privacySettings: UserPrivacySettingsPayload? = nil,
        pushPreference: PushPreferencesResponse? = nil
    ) -> OwnUserResponse {
        .init(
            id: userPayload.id,
            name: userPayload.name,
            imageURL: userPayload.imageURL,
            role: userPayload.userRole,
            teamsRole: userPayload.teamsRolePayload,
            createdAt: userPayload.createdAt,
            updatedAt: userPayload.updatedAt,
            deactivatedAt: userPayload.deactivatedAt,
            lastActiveAt: userPayload.lastActiveAt,
            isOnline: userPayload.isOnline,
            isInvisible: userPayload.isInvisible,
            isBanned: userPayload.isBanned,
            teams: userPayload.teams,
            language: userPayload.language.isEmpty ? nil : userPayload.language,
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

//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

typealias CurrentUserPayload = OwnUserResponse

extension OwnUserResponse {
    var extraData: [String: RawJSON] { custom }

    var imageURL: URL? { image.flatMap(URL.init(string:)) }

    var isBanned: Bool { banned ?? false }

    var isOnline: Bool { online }

    var lastActiveAt: Date? { lastActive }
}

extension OwnUserResponse {
    convenience init(
        id: String,
        name: String?,
        imageURL: URL?,
        role: UserRole,
        teamsRole: [String: UserRole]?,
        createdAt: Date,
        updatedAt: Date,
        deactivatedAt: Date?,
        lastActiveAt: Date?,
        isOnline: Bool,
        isInvisible: Bool,
        isBanned: Bool,
        teams: [TeamId] = [],
        language: String?,
        extraData: [String: RawJSON],
        devices: [Device] = [],
        mutedUsers: [MutedUserPayload] = [],
        mutedChannels: [MutedChannelPayload] = [],
        unreadCount: UnreadCountPayload? = nil,
        totalUnreadCountByTeam: [TeamId: Int]? = nil,
        privacySettings: UserPrivacySettings? = nil,
        blockedUserIds: Set<UserId> = [],
        pushPreference: PushPreference?
    ) {
        self.init(
            banned: isBanned,
            blockedUserIds: Array(blockedUserIds),
            channelMutes: mutedChannels,
            createdAt: createdAt,
            custom: extraData,
            deactivatedAt: deactivatedAt,
            devices: devices,
            id: id,
            image: imageURL?.absoluteString,
            invisible: isInvisible,
            language: language,
            lastActive: lastActiveAt,
            mutes: mutedUsers,
            name: name,
            online: isOnline,
            privacySettings: privacySettings,
            pushPreferences: pushPreference,
            role: role.rawValue,
            teams: teams,
            teamsRole: teamsRole?.mapValues(\.rawValue),
            totalUnreadCount: unreadCount?.messages,
            totalUnreadCountByTeam: totalUnreadCountByTeam,
            unreadChannels: unreadCount?.channels,
            unreadThreads: unreadCount?.threads,
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
        devices: [Device] = [],
        mutedUsers: [MutedUserPayload] = [],
        teams: [TeamId] = [],
        language: String? = nil,
        mutedChannels: [MutedChannelPayload] = [],
        pushPreference: PushPreference? = nil
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
        userPayload: UserPayload,
        unreadCount: UnreadCountPayload? = .dummy,
        devices: [Device] = [],
        mutedUsers: [MutedUserPayload] = [],
        mutedChannels: [MutedChannelPayload] = [],
        totalUnreadCountByTeam: [TeamId: Int]? = nil,
        privacySettings: UserPrivacySettings? = nil,
        pushPreference: PushPreference? = nil
    ) -> OwnUserResponse {
        .init(
            id: userPayload.id,
            name: userPayload.name,
            imageURL: userPayload.imageURL,
            role: UserRole(rawValue: userPayload.role),
            teamsRole: userPayload.teamsRole?.mapValues { UserRole(rawValue: $0) },
            createdAt: userPayload.createdAt,
            updatedAt: userPayload.updatedAt,
            deactivatedAt: userPayload.deactivatedAt,
            lastActiveAt: userPayload.lastActiveAt,
            isOnline: userPayload.isOnline,
            isInvisible: true,
            isBanned: userPayload.isBanned,
            teams: userPayload.teams ?? [],
            language: userPayload.language,
            extraData: userPayload.extraData,
            devices: devices,
            mutedUsers: mutedUsers,
            mutedChannels: mutedChannels,
            unreadCount: unreadCount,
            totalUnreadCountByTeam: totalUnreadCountByTeam,
            privacySettings: privacySettings,
            pushPreference: pushPreference
        )
    }
}

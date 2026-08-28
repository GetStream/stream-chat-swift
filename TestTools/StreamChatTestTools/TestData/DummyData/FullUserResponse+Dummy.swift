//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import XCTest

extension FullUserResponse {
    /// Returns a dummy full user response with the given `id` and `extraData`
    static func dummy(
        userId: UserId,
        name: String? = .unique,
        imageUrl: URL? = .unique(),
        role: UserRole = .admin,
        teamsRole: [String: UserRole]? = nil,
        extraData: [String: RawJSON] = [:],
        teams: [TeamId] = [.unique, .unique, .unique],
        language: String? = nil,
        isOnline: Bool = true,
        isInvisible: Bool = false,
        isBanned: Bool = false,
        updatedAt: Date = .unique,
        deactivatedAt: Date? = nil,
        devices: [Device] = [],
        mutedUsers: [MutedUserPayload] = [],
        mutedChannels: [MutedChannelPayload] = [],
        unreadCount: UnreadCountPayload? = nil,
        privacySettings: UserPrivacySettings? = nil,
        blockedUserIds: Set<UserId> = []
    ) -> FullUserResponse {
        .init(
            banned: isBanned,
            blockedUserIds: Array(blockedUserIds),
            channelMutes: mutedChannels,
            createdAt: .unique,
            custom: extraData,
            deactivatedAt: deactivatedAt,
            devices: devices,
            id: userId,
            image: imageUrl?.absoluteString,
            invisible: isInvisible,
            language: language ?? "",
            lastActive: .unique,
            mutes: mutedUsers,
            name: name,
            online: isOnline,
            privacySettings: privacySettings,
            role: role.rawValue,
            shadowBanned: false,
            teams: teams,
            teamsRole: teamsRole?.mapValues(\.rawValue),
            totalUnreadCount: unreadCount?.messages ?? 0,
            unreadChannels: unreadCount?.channels ?? 0,
            unreadThreads: unreadCount?.threads ?? 0,
            updatedAt: updatedAt
        )
    }

    /// Returns a dummy full user response carrying the same data as the given user payload.
    static func dummy(userPayload: UserPayload) -> FullUserResponse {
        .init(
            banned: userPayload.banned ?? false,
            blockedUserIds: [],
            channelMutes: [],
            createdAt: userPayload.createdAt,
            custom: userPayload.custom,
            deactivatedAt: userPayload.deactivatedAt,
            devices: [],
            id: userPayload.id,
            image: userPayload.image,
            invisible: false,
            language: userPayload.language ?? "",
            lastActive: userPayload.lastActive,
            mutes: [],
            name: userPayload.name,
            online: userPayload.online,
            role: userPayload.role,
            shadowBanned: false,
            teams: userPayload.teams ?? [],
            teamsRole: userPayload.teamsRole,
            totalUnreadCount: 0,
            unreadChannels: 0,
            unreadThreads: 0,
            updatedAt: userPayload.updatedAt
        )
    }
}

extension XCTestCase {
    var dummyFullUser: FullUserResponse {
        dummyFullUser(id: .unique)
    }

    func dummyFullUser(id: String) -> FullUserResponse {
        .dummy(userPayload: dummyUser(id: id))
    }
}

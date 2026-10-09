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
            user: UserPayload(
                banned: isBanned,
                blockedUserIds: Array(blockedUserIds),
                createdAt: .unique,
                custom: extraData,
                deactivatedAt: deactivatedAt,
                id: userId,
                image: imageUrl?.absoluteString,
                language: language ?? "",
                lastActive: .unique,
                name: name,
                online: isOnline,
                role: role.rawValue,
                teams: teams,
                teamsRole: teamsRole?.mapValues(\.rawValue),
                updatedAt: updatedAt
            ),
            channelMutes: mutedChannels,
            devices: devices,
            invisible: isInvisible,
            mutes: mutedUsers,
            privacySettings: privacySettings,
            shadowBanned: false,
            totalUnreadCount: unreadCount?.messages ?? 0,
            unreadChannels: unreadCount?.channels ?? 0,
            unreadThreads: unreadCount?.threads ?? 0
        )
    }

    /// Returns a dummy full user response carrying the same data as the given user payload.
    static func dummy(userPayload: UserPayload) -> FullUserResponse {
        .init(
            user: userPayload,
            channelMutes: [],
            devices: [],
            invisible: false,
            mutes: [],
            shadowBanned: false,
            totalUnreadCount: 0,
            unreadChannels: 0,
            unreadThreads: 0
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

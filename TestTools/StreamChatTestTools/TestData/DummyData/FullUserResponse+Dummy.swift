//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension FullUserResponse {
    static func dummy(
        userId: UserId,
        name: String = .unique,
        imageUrl: URL? = .unique(),
        role: UserRole = .admin,
        teamsRole: [String: UserRole]? = nil,
        extraData: [String: RawJSON] = [:],
        teams: [TeamId] = [.unique, .unique, .unique],
        language: String? = nil,
        isBanned: Bool = false,
        updatedAt: Date = .unique,
        deactivatedAt: Date? = nil,
        privacySettings: PrivacySettingsResponse? = nil
    ) -> FullUserResponse {
        FullUserResponse(
            avgResponseTime: nil,
            banExpires: nil,
            banned: isBanned,
            blockedUserIds: [],
            channelMutes: [],
            createdAt: .unique,
            custom: extraData,
            deactivatedAt: deactivatedAt,
            deletedAt: nil,
            devices: [],
            id: userId,
            image: imageUrl?.absoluteString,
            invisible: true,
            language: language ?? "",
            lastActive: .unique,
            mutes: [],
            name: name,
            online: true,
            privacySettings: privacySettings,
            revokeTokensIssuedBefore: nil,
            role: role.rawValue,
            shadowBanned: false,
            teams: teams,
            teamsRole: teamsRole?.mapValues(\.rawValue),
            totalUnreadCount: 0,
            unreadChannels: 0,
            unreadCount: 0,
            unreadThreads: 0,
            updatedAt: updatedAt
        )
    }
}

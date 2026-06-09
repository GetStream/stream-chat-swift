//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension CreateGuestResponse {
    func validatedToken() throws -> Token {
        let token = try Token(rawValue: accessToken)
        guard user.id == token.userId else {
            throw ClientError.InvalidToken("Token has different user_id")
        }
        return token
    }
}

extension FullUserResponse {
    func asOwnUserResponse() -> OwnUserResponse {
        OwnUserResponse(
            avgResponseTime: avgResponseTime,
            banned: banned,
            blockedUserIds: blockedUserIds,
            channelMutes: channelMutes,
            createdAt: createdAt,
            custom: custom,
            deactivatedAt: deactivatedAt,
            deletedAt: deletedAt,
            devices: devices,
            id: id,
            image: image,
            invisible: invisible,
            language: language,
            lastActive: lastActive,
            latestHiddenChannels: latestHiddenChannels,
            mutes: mutes,
            name: name,
            online: online,
            privacySettings: privacySettings,
            pushPreferences: nil,
            revokeTokensIssuedBefore: revokeTokensIssuedBefore,
            role: role,
            teams: teams,
            teamsRole: teamsRole,
            totalUnreadCount: totalUnreadCount,
            unreadChannels: unreadChannels,
            unreadCount: unreadCount,
            unreadThreads: unreadThreads,
            updatedAt: updatedAt
        )
    }

    func asUserResponse() -> UserResponse {
        UserResponse(
            avgResponseTime: avgResponseTime,
            banned: banned,
            blockedUserIds: [],
            createdAt: createdAt,
            custom: custom,
            deactivatedAt: deactivatedAt,
            id: id,
            image: image,
            language: language,
            lastActive: lastActive,
            name: name,
            online: online,
            role: role,
            teams: teams,
            teamsRole: teamsRole,
            updatedAt: updatedAt
        )
    }
}

extension OwnUserResponse {
    func asUserResponse() -> UserResponse {
        UserResponse(
            avgResponseTime: avgResponseTime,
            banned: banned,
            blockedUserIds: [],
            createdAt: createdAt,
            custom: custom,
            deactivatedAt: deactivatedAt,
            id: id,
            image: imageURL?.absoluteString,
            language: language,
            lastActive: lastActive,
            name: name,
            online: online,
            role: role,
            teams: teams,
            teamsRole: teamsRole,
            updatedAt: updatedAt
        )
    }

    var imageURL: URL? {
        image.flatMap(URL.init(string:))
    }

    var unreadCountPayload: UnreadCountPayload? {
        UnreadCountPayload(
            channels: unreadChannels,
            messages: unreadCount,
            threads: unreadThreads >= 0 ? unreadThreads : nil
        )
    }

    var userRole: UserRole {
        UserRole(rawValue: role)
    }
}

extension QueryUsersResponse {
    var userResponses: [UserResponse] {
        users.map { $0.asUserResponse() }
    }
}

extension UserPrivacySettings {
    var asPrivacySettingsResponse: PrivacySettingsResponse {
        PrivacySettingsResponse(
            deliveryReceipts: deliveryReceipts.map { .init(enabled: $0.enabled) },
            readReceipts: readReceipts.map { .init(enabled: $0.enabled) },
            typingIndicators: typingIndicators.map { .init(enabled: $0.enabled) }
        )
    }
}

extension UserResponse {
    func asFullUserResponse() -> FullUserResponse {
        FullUserResponse(
            avgResponseTime: avgResponseTime,
            banned: banned,
            blockedUserIds: [],
            channelMutes: [],
            createdAt: createdAt,
            custom: custom,
            deactivatedAt: deactivatedAt,
            devices: [],
            id: id,
            image: image,
            invisible: false,
            language: language,
            lastActive: lastActive,
            mutes: [],
            name: name,
            online: online,
            role: userRole.rawValue,
            shadowBanned: false,
            teams: teams,
            teamsRole: teamsRole,
            totalUnreadCount: 0,
            unreadChannels: 0,
            unreadCount: 0,
            unreadThreads: 0,
            updatedAt: updatedAt
        )
    }

    func asUserResponseCommonFields() -> UserResponseCommonFields {
        UserResponseCommonFields(
            avgResponseTime: avgResponseTime,
            banned: banned,
            blockedUserIds: blockedUserIds,
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

    func asUserResponsePrivacyFields() -> UserResponsePrivacyFields {
        UserResponsePrivacyFields(
            avgResponseTime: avgResponseTime,
            banned: banned,
            blockedUserIds: blockedUserIds,
            createdAt: createdAt,
            custom: custom,
            deactivatedAt: deactivatedAt,
            deletedAt: deletedAt,
            id: id,
            image: image,
            invisible: nil,
            language: language,
            lastActive: lastActive,
            name: name,
            online: online,
            privacySettings: nil,
            revokeTokensIssuedBefore: revokeTokensIssuedBefore,
            role: role,
            teams: teams,
            teamsRole: teamsRole,
            updatedAt: updatedAt
        )
    }

    var imageURL: URL? {
        image.flatMap(URL.init(string:))
    }

    var teamsUserRole: [String: UserRole]? {
        teamsRole?.mapValues { UserRole(rawValue: $0) }
    }

    var userRole: UserRole {
        UserRole(rawValue: role)
    }
}

extension UserResponseCommonFields {
    func asUserResponse() -> UserResponse {
        UserResponse(
            avgResponseTime: avgResponseTime,
            banned: banned,
            blockedUserIds: blockedUserIds,
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
}

extension UserResponsePrivacyFields {
    func asUserResponse() -> UserResponse {
        UserResponse(
            avgResponseTime: avgResponseTime,
            banned: banned,
            blockedUserIds: blockedUserIds,
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
}

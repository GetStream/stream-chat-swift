//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension UserResponse {
    /// Returns a dummy user payload with the given `id` and `extraData`
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
        isBanned: Bool = false,
        updatedAt: Date = .unique,
        deactivatedAt: Date? = nil
    ) -> UserResponse {
        .init(
            banned: isBanned,
            blockedUserIds: [],
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
        )
    }
}

extension UserResponseCommonFields {
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
        isBanned: Bool = false,
        updatedAt: Date = .unique,
        deactivatedAt: Date? = nil
    ) -> UserResponseCommonFields {
        UserResponse.dummy(
            userId: userId,
            name: name,
            imageUrl: imageUrl,
            role: role,
            teamsRole: teamsRole,
            extraData: extraData,
            teams: teams,
            language: language,
            isOnline: isOnline,
            isBanned: isBanned,
            updatedAt: updatedAt,
            deactivatedAt: deactivatedAt
        ).asUserResponseCommonFields()
    }
}

extension UserResponsePrivacyFields {
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
        isBanned: Bool = false,
        updatedAt: Date = .unique,
        deactivatedAt: Date? = nil
    ) -> UserResponsePrivacyFields {
        UserResponse.dummy(
            userId: userId,
            name: name,
            imageUrl: imageUrl,
            role: role,
            teamsRole: teamsRole,
            extraData: extraData,
            teams: teams,
            language: language,
            isOnline: isOnline,
            isBanned: isBanned,
            updatedAt: updatedAt,
            deactivatedAt: deactivatedAt
        ).asUserResponsePrivacyFields()
    }
}

extension OwnUserResponse {
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
    ) -> OwnUserResponse {
        .dummy(
            userId: userId,
            name: name,
            imageURL: imageUrl,
            updatedAt: updatedAt,
            deactivatedAt: deactivatedAt,
            isInvisible: true,
            isBanned: isBanned,
            role: role,
            teamsRole: teamsRole,
            unreadCount: nil,
            extraData: extraData,
            teams: teams,
            language: language,
            privacySettings: privacySettings ?? PrivacySettingsResponse.dummy()
        )
    }
}

extension QueryUsersResponse {
    static func dummy(
        duration: String = "",
        users: [UserResponse] = []
    ) -> QueryUsersResponse {
        .init(duration: duration, users: users.map { $0.asFullUserResponse() })
    }
}

extension UpdateUsersResponse {
    static func dummy(
        duration: String = "",
        membershipDeletionTaskId: String = "",
        user: FullUserResponse
    ) -> UpdateUsersResponse {
        .init(duration: duration, membershipDeletionTaskId: membershipDeletionTaskId, users: [user.id: user])
    }
}

extension PushPreferencesResponse {
    static func dummy(
        chatLevel: String? = PushPreferenceLevel.all.rawValue,
        disabledUntil: Date? = nil
    ) -> PushPreferencesResponse {
        .init(
            chatLevel: chatLevel,
            disabledUntil: disabledUntil
        )
    }
}

extension ChannelPushPreferencesResponse {
    static func dummy(
        chatLevel: String? = PushPreferenceLevel.all.rawValue,
        disabledUntil: Date? = nil
    ) -> ChannelPushPreferencesResponse {
        .init(
            chatLevel: chatLevel,
            disabledUntil: disabledUntil
        )
    }
}

extension UpsertPushPreferencesResponse {
    static func dummy(
        duration: String = "",
        userChannelPreferences: [String: [String: ChannelPushPreferencesResponse?]] = [:],
        userPreferences: [String: PushPreferencesResponse?] = [:]
    ) -> UpsertPushPreferencesResponse {
        .init(
            duration: duration,
            userChannelPreferences: userChannelPreferences,
            userPreferences: userPreferences
        )
    }
}

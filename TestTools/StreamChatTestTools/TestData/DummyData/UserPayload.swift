//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension UserPayload {
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
    ) -> UserPayload {
        .init(
            id: userId,
            name: name,
            imageURL: imageUrl,
            role: role,
            teamsRole: teamsRole,
            createdAt: .unique,
            updatedAt: updatedAt,
            deactivatedAt: deactivatedAt,
            lastActiveAt: .unique,
            isOnline: isOnline,
            isInvisible: true,
            isBanned: isBanned,
            teams: teams,
            language: language,
            extraData: extraData
        )
    }
}

extension CurrentUserPayload {
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
        privacySettings: UserPrivacySettingsPayload? = nil
    ) -> CurrentUserPayload {
        .init(
            id: userId,
            name: name,
            imageURL: imageUrl,
            role: role,
            teamsRole: teamsRole,
            createdAt: .unique,
            updatedAt: updatedAt,
            deactivatedAt: deactivatedAt,
            lastActiveAt: .unique,
            isOnline: true,
            isInvisible: true,
            isBanned: isBanned,
            teams: teams,
            language: language,
            extraData: extraData,
            privacySettings: privacySettings,
            pushPreference: nil
        )
    }
}

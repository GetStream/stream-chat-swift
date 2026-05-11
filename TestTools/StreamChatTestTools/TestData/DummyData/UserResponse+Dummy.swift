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
        privacySettings: UserPrivacySettingsPayload? = nil
    ) -> OwnUserResponse {
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
            privacySettings: privacySettings ?? .init(
                typingIndicators: .init(enabled: true),
                readReceipts: .init(enabled: true),
                deliveryReceipts: .init(enabled: true)
            ),
            pushPreference: nil
        )
    }
}

//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension UserObject {
    /// Returns a dummy user payload with the given `id` and `extraData`
    static func dummy(
        userId: UserId,
        name: String = .unique,
        imageUrl: URL? = .unique(),
        role: UserRole = .admin,
        extraData: [String: RawJSON] = [:],
        teams: [TeamId] = [.unique, .unique, .unique],
        language: String? = nil,
        isBanned: Bool = false,
        updatedAt: Date = .unique,
        lastActive: Date = .unique,
        deactivatedAt: Date? = nil
    ) -> UserObject {
        return UserObject(
            id: userId,
            banned: isBanned,
            createdAt: .unique,
            deactivatedAt: deactivatedAt,
            invisible: true,
            language: language,
            lastActive: lastActive,
            online: true,
            role: role.rawValue,
            updatedAt: updatedAt,
            teams: teams,
            custom: extraData
        )
    }
}

extension UserResponse {
    /// Returns a dummy user payload with the given `id` and `extraData`
    static func dummy(
        userId: UserId,
        name: String = .unique,
        imageUrl: URL? = .unique(),
        role: UserRole = .admin,
        extraData: [String: RawJSON] = [:],
        teams: [TeamId] = [.unique, .unique, .unique],
        language: String? = nil,
        isBanned: Bool = false,
        updatedAt: Date = .unique,
        lastActive: Date = .unique,
        deactivatedAt: Date? = nil
    ) -> UserResponse {
        .init(
            banned: isBanned,
            createdAt: .unique,
            id: userId,
            language: language ?? "en",
            online: false,
            role: role.rawValue,
            updatedAt: updatedAt,
            teams: teams,
            custom: extraData,
            deletedAt: nil,
            image: imageUrl?.absoluteString,
            name: name
        )
    }
}

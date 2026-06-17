//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension UserResponse {
    /// Returns a dummy user response with the given `userId` and `extraData`.
    static func dummy(
        deactivatedAt: Date? = nil,
        extraData: [String: RawJSON] = [:],
        imageUrl: URL? = .unique(),
        isBanned: Bool = false,
        isOnline: Bool = true,
        language: String? = nil,
        name: String? = .unique,
        role: UserRole = .admin,
        teams: [TeamId] = [.unique, .unique, .unique],
        teamsRole: [String: UserRole]? = nil,
        updatedAt: Date = .unique,
        userId: UserId
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

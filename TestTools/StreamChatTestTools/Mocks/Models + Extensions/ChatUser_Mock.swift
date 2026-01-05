//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

public extension ChatUser {
    /// Creates a new `ChatUser` object from the provided data.
    static func mock(
        id: UserId,
        name: String? = nil,
        imageURL: URL? = nil,
        isOnline: Bool = false,
        isBanned: Bool = false,
        isFlaggedByCurrentUser: Bool = false,
        userRole: UserRole = .user,
        teamsRole: [String: UserRole]? = nil,
        createdAt: Date = .init(),
        updatedAt: Date = .init(),
        deactivatedAt: Date? = nil,
        lastActiveAt: Date? = nil,
        teams: Set<TeamId> = [],
        language: TranslationLanguage? = nil,
        avgResponseTime: Int? = nil,
        extraData: [String: RawJSON] = [:]
    ) -> ChatUser {
        .init(
            id: id,
            name: name,
            imageURL: imageURL,
            isOnline: isOnline,
            isBanned: isBanned,
            isFlaggedByCurrentUser: isFlaggedByCurrentUser,
            userRole: userRole,
            teamsRole: teamsRole,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deactivatedAt: deactivatedAt,
            lastActiveAt: lastActiveAt,
            teams: teams,
            language: language,
            avgResponseTime: avgResponseTime,
            extraData: extraData
        )
    }
}

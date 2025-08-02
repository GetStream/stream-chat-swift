//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

extension UserPayload {
    /// Converts the UserPayload to a ChatUser model.
    /// - Returns: A ChatUser instance.
    func asModel() -> ChatUser {
        ChatUser(
            id: id,
            name: name,
            imageURL: imageURL,
            isOnline: isOnline,
            isBanned: isBanned,
            isFlaggedByCurrentUser: false,
            userRole: role,
            teamsRole: teamsRole,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deactivatedAt: deactivatedAt,
            lastActiveAt: lastActiveAt,
            teams: Set(teams),
            language: language.flatMap { TranslationLanguage(languageCode: $0) },
            avgResponseTime: avgResponseTime,
            extraData: extraData
        )
    }
}

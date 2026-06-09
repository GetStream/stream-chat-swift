//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension UserResponse {
    /// Converts the UserResponse to a ChatUser model.
    /// - Returns: A ChatUser instance.
    func asModel() -> ChatUser {
        ChatUser(
            id: id,
            name: name,
            imageURL: imageURL,
            isOnline: online,
            isBanned: banned,
            isFlaggedByCurrentUser: false,
            userRole: userRole,
            teamsRole: teamsUserRole,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deactivatedAt: deactivatedAt,
            lastActiveAt: lastActive,
            teams: Set(teams),
            language: language.isEmpty ? nil : TranslationLanguage(languageCode: language),
            avgResponseTime: avgResponseTime,
            extraData: custom
        )
    }
}

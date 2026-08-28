//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension FullUserResponse {
    /// Converts the FullUserResponse to a ChatUser model.
    /// - Returns: A ChatUser instance.
    func asModel() -> ChatUser {
        ChatUser(
            id: id,
            name: name,
            imageURL: image.flatMap(URL.init(string:)),
            isOnline: online,
            isBanned: banned,
            isFlaggedByCurrentUser: false,
            userRole: UserRole(rawValue: role),
            teamsRole: teamsRole?.mapValues { UserRole(rawValue: $0) },
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

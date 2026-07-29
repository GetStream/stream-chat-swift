//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension UserPayload {
    var extraData: [String: RawJSON] { custom }

    var imageURL: URL? { image.flatMap(URL.init(string:)) }

    var isBanned: Bool { banned ?? false }

    var isOnline: Bool { online }

    var lastActiveAt: Date? { lastActive }

    convenience init(
        id: String,
        name: String?,
        imageURL: URL?,
        role: UserRole,
        teamsRole: [String: UserRole]?,
        createdAt: Date,
        updatedAt: Date,
        deactivatedAt: Date?,
        lastActiveAt: Date?,
        isOnline: Bool,
        isBanned: Bool,
        teams: [TeamId] = [],
        language: String?,
        avgResponseTime: Int? = nil,
        extraData: [String: RawJSON]
    ) {
        self.init(
            avgResponseTime: avgResponseTime,
            banned: isBanned,
            createdAt: createdAt,
            custom: extraData,
            deactivatedAt: deactivatedAt,
            id: id,
            image: imageURL?.absoluteString,
            language: language,
            lastActive: lastActiveAt,
            name: name,
            online: isOnline,
            role: role.rawValue,
            teams: teams,
            teamsRole: teamsRole?.mapValues(\.rawValue),
            updatedAt: updatedAt
        )
    }
}

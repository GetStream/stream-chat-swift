//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension UserPayload {
    /// Returns a dummy user payload with the given `id` and `extraData`
    static func dummy(
        userId: UserId,
        name: String = .unique,
        imageUrl: URL? = .unique(),
        role: UserRole = .admin,
        extraData: [String: RawJSON] = [:],
        teams: [TeamId] = [.unique, .unique, .unique],
        isBanned: Bool = false,
        updatedAt: Date = .unique
    ) -> UserPayload {
        .init(
            id: userId,
            name: name,
            imageURL: imageUrl,
            role: role,
            createdAt: .unique,
            updatedAt: updatedAt,
            lastActiveAt: .unique,
            isOnline: true,
            isInvisible: true,
            isBanned: isBanned,
            teams: teams,
            extraData: extraData
        )
    }
}

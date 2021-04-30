//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension UserPayload where ExtraData == NoExtraData {
    /// Returns a dummy user payload with the given `id` and `extraData`
    static func dummy(
        userId: UserId,
        name: String = .unique,
        imageUrl: URL? = .unique(),
        extraData: NoExtraData = .defaultValue,
        teams: [TeamId] = [.unique, .unique, .unique],
        isBanned: Bool = false,
        updatedAt: Date = .unique
    ) -> UserPayload {
        .init(
            id: userId,
            name: name,
            imageURL: imageUrl,
            role: .admin,
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

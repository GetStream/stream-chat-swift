//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension UserPayload where ExtraData == NoExtraData.User {
    /// Returns a dummy user payload with the given `id` and `extraData`
    static func dummy(
        userId: UserId,
        name: String = .unique,
        imageUrl: URL? = .unique(),
        extraData: NoExtraData.User = .defaultValue
    ) -> UserPayload {
        .init(
            id: userId,
            name: name,
            imageURL: imageUrl,
            role: .admin,
            createdAt: .unique,
            updatedAt: .unique,
            lastActiveAt: .unique,
            isOnline: true,
            isInvisible: true,
            isBanned: true,
            teams: [],
            extraData: extraData
        )
    }
}

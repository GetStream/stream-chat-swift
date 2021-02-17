//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

public extension _ChatUser {
    /// Creates a new `_ChatUser` object from the provided data.
    static func mock(
        id: UserId,
        name: String? = nil,
        imageURL: URL? = nil,
        isOnline: Bool = false,
        isBanned: Bool = false,
        isFlaggedByCurrentUser: Bool = false,
        userRole: UserRole = .user,
        createdAt: Date = .init(),
        updatedAt: Date = .init(),
        lastActiveAt: Date? = nil,
        teams: [String] = [],
        extraData: ExtraData = .defaultValue
    ) -> _ChatUser {
        .init(
            id: id,
            name: name,
            imageURL: imageURL,
            isOnline: isOnline,
            isBanned: isBanned,
            isFlaggedByCurrentUser: isFlaggedByCurrentUser,
            userRole: userRole,
            createdAt: createdAt,
            updatedAt: updatedAt,
            lastActiveAt: lastActiveAt,
            teams: teams,
            extraData: extraData
        )
    }
}

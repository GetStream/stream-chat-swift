//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChatClient

extension CurrentUserPayload {
    /// Returns a dummy current user payload with the given UserId and extra data
    static func dummy<T: UserExtraData>(
        userId: UserId,
        role: UserRole,
        unreadCount: UnreadCount? = .dummy,
        extraData: T = .defaultValue
    ) -> CurrentUserPayload<T> {
        .init(
            id: userId,
            role: role,
            createdAt: .unique,
            updatedAt: .unique,
            lastActiveAt: .unique,
            isOnline: true,
            isInvisible: true,
            isBanned: true,
            teams: [],
            extraData: extraData,
            devices: [.init(.unique)],
            mutedUsers: [],
            unreadCount: unreadCount
        )
    }
}

//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension CurrentUserPayload {
    /// Returns a dummy current user payload with the given UserId and extra data
    static func dummy<T: UserExtraData>(
        userId: UserId,
        role: UserRole,
        unreadCount: UnreadCount? = .dummy,
        extraData: T = .defaultValue,
        devices: [DevicePayload] = [],
        mutedUsers: [MutedUserPayload<T>] = []
    ) -> CurrentUserPayload<T> {
        .init(
            id: userId,
            name: .unique,
            imageURL: nil,
            role: role,
            createdAt: .unique,
            updatedAt: .unique,
            lastActiveAt: .unique,
            isOnline: true,
            isInvisible: true,
            isBanned: true,
            teams: [],
            extraData: extraData,
            devices: devices,
            mutedUsers: mutedUsers,
            unreadCount: unreadCount
        )
    }
}

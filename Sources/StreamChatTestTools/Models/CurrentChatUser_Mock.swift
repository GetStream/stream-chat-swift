//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

public extension _CurrentChatUser {
    /// Creates a new `_CurrentChatUser` object from the provided data.
    static func mock(
        id: String,
        name: String? = nil,
        imageURL: URL? = nil,
        isOnline: Bool = false,
        isBanned: Bool = false,
        userRole: UserRole = .user,
        createdAt: Date = .init(),
        updatedAt: Date = .init(),
        lastActiveAt: Date? = nil,
        teams: Set<TeamId> = [],
        extraData: ExtraData = .defaultValue,
        devices: [Device] = [],
        currentDevice: Device? = nil,
        mutedUsers: Set<_ChatUser<ExtraData>> = [],
        flaggedUsers: Set<_ChatUser<ExtraData>> = [],
        flaggedMessageIDs: Set<MessageId> = [],
        unreadCount: UnreadCount = .noUnread
    ) -> _CurrentChatUser {
        .init(
            id: id,
            name: name,
            imageURL: imageURL,
            isOnline: isOnline,
            isBanned: isBanned,
            userRole: userRole,
            createdAt: createdAt,
            updatedAt: updatedAt,
            lastActiveAt: lastActiveAt,
            teams: teams,
            extraData: extraData,
            devices: devices,
            currentDevice: currentDevice,
            mutedUsers: mutedUsers,
            flaggedUsers: flaggedUsers,
            flaggedMessageIDs: flaggedMessageIDs,
            unreadCount: unreadCount
        )
    }
}

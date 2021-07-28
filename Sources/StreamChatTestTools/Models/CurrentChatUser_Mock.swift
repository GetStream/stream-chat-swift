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
        extraData: ExtraData.User = .defaultValue,
        extraDataMap: CustomData = .defaultValue,
        devices: [Device] = [],
        currentDevice: Device? = nil,
        mutedUsers: Set<_ChatUser<ExtraData.User>> = [],
        flaggedUsers: Set<_ChatUser<ExtraData.User>> = [],
        flaggedMessageIDs: Set<MessageId> = [],
        unreadCount: UnreadCount = .noUnread,
        mutedChannels: Set<_ChatChannel<ExtraData>> = []
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
            extraDataMap: extraDataMap,
            devices: devices,
            currentDevice: currentDevice,
            mutedUsers: mutedUsers,
            flaggedUsers: flaggedUsers,
            flaggedMessageIDs: flaggedMessageIDs,
            unreadCount: unreadCount,
            mutedChannels: { mutedChannels },
            underlyingContext: nil
        )
    }
}

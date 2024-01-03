//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

public extension CurrentChatUser {
    /// Creates a new `CurrentChatUser` object from the provided data.
    static func mock(
        id: String,
        name: String? = nil,
        imageURL: URL? = nil,
        isOnline: Bool = false,
        isInvisible: Bool = false,
        isBanned: Bool = false,
        userRole: UserRole = .user,
        createdAt: Date = .init(),
        updatedAt: Date = .init(),
        deactivatedAt: Date? = nil,
        lastActiveAt: Date? = nil,
        teams: Set<TeamId> = [],
        language: TranslationLanguage? = nil,
        extraData: [String: RawJSON] = [:],
        devices: [Device] = [],
        currentDevice: Device? = nil,
        mutedUsers: Set<ChatUser> = [],
        flaggedUsers: Set<ChatUser> = [],
        flaggedMessageIDs: Set<MessageId> = [],
        unreadCount: UnreadCount = .noUnread,
        mutedChannels: Set<ChatChannel> = []
    ) -> CurrentChatUser {
        .init(
            id: id,
            name: name,
            imageURL: imageURL,
            isOnline: isOnline,
            isInvisible: isInvisible,
            isBanned: isBanned,
            userRole: userRole,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deactivatedAt: deactivatedAt,
            lastActiveAt: lastActiveAt,
            teams: teams,
            language: language,
            extraData: extraData,
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

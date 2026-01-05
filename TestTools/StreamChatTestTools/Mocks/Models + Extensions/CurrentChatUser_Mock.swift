//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

public extension CurrentChatUser {
    /// Creates a new `CurrentChatUser` object from the provided data.
    static func mock(
        currentUserId: UserId,
        name: String? = nil,
        imageURL: URL? = nil,
        isOnline: Bool = false,
        isInvisible: Bool = false,
        isBanned: Bool = false,
        userRole: UserRole = .user,
        teamsRole: [String: UserRole]? = nil,
        createdAt: Date = .init(),
        updatedAt: Date = .init(),
        deactivatedAt: Date? = nil,
        lastActiveAt: Date? = nil,
        teams: Set<TeamId> = [],
        language: TranslationLanguage? = nil,
        blockedUserIds: Set<UserId> = [],
        extraData: [String: RawJSON] = [:],
        devices: [Device] = [],
        currentDevice: Device? = nil,
        mutedUsers: Set<ChatUser> = [],
        blockedUsers: Set<BlockedUserDetails> = [],
        flaggedUsers: Set<ChatUser> = [],
        flaggedMessageIDs: Set<MessageId> = [],
        unreadCount: UnreadCount = .noUnread,
        mutedChannels: Set<ChatChannel> = [],
        privacySettings: UserPrivacySettings = .init(
            typingIndicators: .init(enabled: true),
            readReceipts: .init(enabled: true),
            deliveryReceipts: .init(enabled: true)
        ),
        avgResponseTime: Int? = nil
    ) -> CurrentChatUser {
        .init(
            id: currentUserId,
            name: name,
            imageURL: imageURL,
            isOnline: isOnline,
            isInvisible: isInvisible,
            isBanned: isBanned,
            userRole: userRole,
            teamsRole: teamsRole,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deactivatedAt: deactivatedAt,
            lastActiveAt: lastActiveAt,
            teams: teams,
            language: language,
            extraData: extraData,
            devices: devices,
            currentDevice: currentDevice,
            blockedUserIds: blockedUserIds,
            mutedUsers: mutedUsers,
            flaggedUsers: flaggedUsers,
            flaggedMessageIDs: flaggedMessageIDs,
            unreadCount: unreadCount,
            mutedChannels: mutedChannels,
            privacySettings: privacySettings,
            avgResponseTime: avgResponseTime
        )
    }
}

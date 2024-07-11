//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

extension UserId {
    /// The prefix used for anonymous user ids
    private static let anonymousIdPrefix = "__anonymous__"

    /// Creates a new anonymous User id.
    static var anonymous: UserId {
        anonymousIdPrefix + UUID().uuidString
    }

    var isAnonymousUser: Bool {
        hasPrefix(Self.anonymousIdPrefix)
    }
}

/// A type representing the currently logged-in user. `CurrentChatUser` is an immutable snapshot of a current user entity at
/// the given time.
///
public class CurrentChatUser: ChatUser {
    /// A list of devices associcated with the user.
    public let devices: [Device]

    /// The current device of the user. `nil` if no current device is assigned.
    public let currentDevice: Device?

    /// A set of users muted by the user.
    public let mutedUsers: Set<ChatUser>
    
    /// A list of blocked user ids.
    public let blockedUserIds: Set<UserId>

    /// A set of users flagged by the user.
    ///
    /// - Note: Please be aware that the value of this field is not persisted on the server,
    /// and is valid only locally for the current session.
    public let flaggedUsers: Set<ChatUser>

    /// A set of message ids flagged by the user.
    ///
    /// - Note: Please be aware that the value of this field is not persisted on the server,
    /// and is valid only locally for the current session.
    public let flaggedMessageIDs: Set<MessageId>

    /// A set of channels muted by the current user.
    ///
    /// - Important: The `mutedChannels` property is loaded and evaluated lazily to maintain high performance.
    public let mutedChannels: Set<ChatChannel>

    /// The unread counts for the current user.
    public let unreadCount: UnreadCount

    /// A Boolean value indicating if the user has opted to hide their online status.
    public let isInvisible: Bool

    /// The current privacy settings of the user.
    public let privacySettings: UserPrivacySettings

    init(
        id: String,
        name: String?,
        imageURL: URL?,
        isOnline: Bool,
        isInvisible: Bool,
        isBanned: Bool,
        userRole: UserRole,
        createdAt: Date,
        updatedAt: Date,
        deactivatedAt: Date?,
        lastActiveAt: Date?,
        teams: Set<TeamId>,
        language: TranslationLanguage?,
        extraData: [String: RawJSON],
        devices: [Device],
        currentDevice: Device?,
        blockedUserIds: Set<UserId>,
        mutedUsers: Set<ChatUser>,
        flaggedUsers: Set<ChatUser>,
        flaggedMessageIDs: Set<MessageId>,
        unreadCount: UnreadCount,
        mutedChannels: Set<ChatChannel>,
        privacySettings: UserPrivacySettings
    ) {
        self.devices = devices
        self.currentDevice = currentDevice
        self.blockedUserIds = blockedUserIds
        self.mutedUsers = mutedUsers
        self.flaggedUsers = flaggedUsers
        self.flaggedMessageIDs = flaggedMessageIDs
        self.unreadCount = unreadCount
        self.isInvisible = isInvisible
        self.privacySettings = privacySettings
        self.mutedChannels = mutedChannels
        
        super.init(
            id: id,
            name: name,
            imageURL: imageURL,
            isOnline: isOnline,
            isBanned: isBanned,
            isFlaggedByCurrentUser: false,
            userRole: userRole,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deactivatedAt: deactivatedAt,
            lastActiveAt: lastActiveAt,
            teams: teams,
            language: language,
            extraData: extraData
        )
    }
}

/// The total unread information from the current user.
public struct CurrentUserUnreads {
    /// The total number of unread channels.
    public let totalUnreadChannelsCount: Int
    /// The total number of unread threads.
    public let totalUnreadThreadsCount: Int
    /// The unread information per channel.
    public let unreadChannels: [UnreadChannel]
    /// The unread information per thread.
    public let unreadThreads: [UnreadThread]
    /// The unread information per channel type.
    public let unreadChannelsByType: [UnreadChannelByType]
}

/// The unread information of a channel.
public struct UnreadChannel {
    /// The channel id.
    public let channelId: ChannelId
    /// The number of unread messages inside the channel.
    public let unreadMessagesCount: Int
    /// The date which the current user last read the channel.
    public let lastRead: Date?
}

/// The unread information from channels with a specific type.
public struct UnreadChannelByType {
    /// The channel type.
    public let channelType: ChannelType
    /// The number of unread channels of this channel type.
    public let unreadChannelCount: Int
    /// The number of unread messages of all the channels with this type.
    public let unreadMessagesCount: Int
}

/// The unread information of a thread.
public struct UnreadThread {
    /// The message id of the root of the thread.
    public let parentMessageId: MessageId
    /// The number of unread replies inside the thread.
    public let unreadRepliesCount: Int
    /// The date which the current user last read the thread.
    public let lastRead: Date?
    /// The id of the last reply which the current user read in the thread.
    public let lastReadMessageId: MessageId?
}

extension CurrentUserUnreadsPayload {
    func asModel() -> CurrentUserUnreads {
        CurrentUserUnreads(
            totalUnreadChannelsCount: totalUnreadCount,
            totalUnreadThreadsCount: totalUnreadThreadsCount,
            unreadChannels: channels.map { .init(
                channelId: $0.channelId,
                unreadMessagesCount: $0.unreadCount,
                lastRead: $0.lastRead
            ) },
            unreadThreads: threads.map { .init(
                parentMessageId: $0.parentMessageId,
                unreadRepliesCount: $0.unreadCount,
                lastRead: $0.lastRead,
                lastReadMessageId: $0.lastReadMessageId
            ) },
            unreadChannelsByType: channelType.map {
                .init(
                    channelType: $0.channelType,
                    unreadChannelCount: $0.channelCount,
                    unreadMessagesCount: $0.unreadCount
                )
            }
        )
    }
}

//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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
public class CurrentChatUser: ChatUser, @unchecked Sendable {
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

    /// Unread channel counts keyed by the backend-provided group identifier.
    public let unreadChannelCountsByGroup: [String: Int]?

    /// A Boolean value indicating if the user has opted to hide their online status.
    public let isInvisible: Bool

    /// The current privacy settings of the user.
    public let privacySettings: UserPrivacySettings
    
    /// Push preference for the user.
    public let pushPreference: PushPreference?

    init(
        id: String,
        name: String?,
        imageURL: URL?,
        isOnline: Bool,
        isInvisible: Bool,
        isBanned: Bool,
        userRole: UserRole,
        teamsRole: [String: UserRole]?,
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
        unreadChannelCountsByGroup: [String: Int]? = nil,
        mutedChannels: Set<ChatChannel>,
        privacySettings: UserPrivacySettings,
        avgResponseTime: Int?,
        pushPreference: PushPreference? = nil
    ) {
        self.devices = devices
        self.currentDevice = currentDevice
        self.blockedUserIds = blockedUserIds
        self.mutedUsers = mutedUsers
        self.flaggedUsers = flaggedUsers
        self.flaggedMessageIDs = flaggedMessageIDs
        self.unreadCount = unreadCount
        self.unreadChannelCountsByGroup = unreadChannelCountsByGroup
        self.isInvisible = isInvisible
        self.privacySettings = privacySettings
        self.mutedChannels = mutedChannels
        self.pushPreference = pushPreference
        
        super.init(
            id: id,
            name: name,
            imageURL: imageURL,
            isOnline: isOnline,
            isBanned: isBanned,
            isFlaggedByCurrentUser: false,
            userRole: userRole,
            teamsRole: teamsRole,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deactivatedAt: deactivatedAt,
            lastActiveAt: lastActiveAt,
            teams: teams,
            language: language,
            avgResponseTime: avgResponseTime,
            extraData: extraData
        )
    }
}

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
    public var mutedChannels: Set<ChatChannel> { _mutedChannels }
    @CoreDataLazy private var _mutedChannels: Set<ChatChannel>

    /// The unread counts for the current user.
    public let unreadCount: UnreadCount

    /// A Boolean value indicating if the user has opted to hide their online status.
    public let isInvisible: Bool

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
        mutedUsers: Set<ChatUser>,
        flaggedUsers: Set<ChatUser>,
        flaggedMessageIDs: Set<MessageId>,
        unreadCount: UnreadCount,
        mutedChannels: @escaping () -> Set<ChatChannel>,
        underlyingContext: NSManagedObjectContext?
    ) {
        self.devices = devices
        self.currentDevice = currentDevice
        self.mutedUsers = mutedUsers
        self.flaggedUsers = flaggedUsers
        self.flaggedMessageIDs = flaggedMessageIDs
        self.unreadCount = unreadCount
        self.isInvisible = isInvisible

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

        $_mutedChannels = (mutedChannels, underlyingContext)
    }
}

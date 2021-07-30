//
// Copyright © 2021 Stream.io Inc. All rights reserved.
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

/// A type representing the currently logged-in user. `_CurrentChatUser` is an immutable snapshot of a current user entity at
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
    
    init(
        id: String,
        name: String?,
        imageURL: URL?,
        isOnline: Bool,
        isBanned: Bool,
        userRole: UserRole,
        createdAt: Date,
        updatedAt: Date,
        lastActiveAt: Date?,
        teams: Set<TeamId>,
        extraData: CustomData,
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
            lastActiveAt: lastActiveAt,
            teams: teams,
            extraData: extraData
        )

        $_mutedChannels = (mutedChannels, underlyingContext)
    }
}

//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

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
/// - Note: `CurrentChatUser` is a typealias of `_CurrentChatUser` with default extra data. If you're using custom extra data,
/// create your own typealias of `_CurrentChatUser`.
///
/// Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).
///
public typealias CurrentChatUser = _CurrentChatUser<NoExtraData>

/// A type representing the currently logged-in user. `_CurrentChatUser` is an immutable snapshot of a current user entity at
/// the given time.
///
/// - Note: `_CurrentChatUser` type is not meant to be used directly. If you're using default extra data, use `CurrentChatUser`
/// typealias instead. If you're using custom extra data, create your own typealias of `CurrentChatUser`.
///
/// Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).
///
public class _CurrentChatUser<ExtraData: UserExtraData>: _ChatUser<ExtraData> {
    /// A list of devices associcated with the user.
    public let devices: [Device]
    
    /// The current device of the user. `nil` if no current device is assigned.
    public let currentDevice: Device?
    
    /// A set of users muted by the user.
    public let mutedUsers: Set<_ChatUser<ExtraData>>
    
    /// A set of users flagged by the user.
    ///
    /// - Note: Please be aware that the value of this field is not persisted on the server,
    /// and is valid only locally for the current session.
    public let flaggedUsers: Set<_ChatUser<ExtraData>>
    
    /// A set of message ids flagged by the user.
    ///
    /// - Note: Please be aware that the value of this field is not persisted on the server,
    /// and is valid only locally for the current session.
    public let flaggedMessageIDs: Set<MessageId>
    
    /// The unread counts for the current user.
    public let unreadCount: UnreadCount
    
    public init(
        id: String,
        name: String? = nil,
        imageURL: URL? = nil,
        isOnline: Bool = false,
        isBanned: Bool = false,
        userRole: UserRole = .user,
        createdAt: Date = .init(),
        updatedAt: Date = .init(),
        lastActiveAt: Date? = nil,
        extraData: ExtraData = .defaultValue,
        devices: [Device] = [],
        currentDevice: Device? = nil,
        mutedUsers: Set<_ChatUser<ExtraData>> = [],
        flaggedUsers: Set<_ChatUser<ExtraData>> = [],
        flaggedMessageIDs: Set<MessageId> = [],
        unreadCount: UnreadCount = .noUnread
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
            userRole: userRole,
            createdAt: createdAt,
            updatedAt: updatedAt,
            lastActiveAt: lastActiveAt,
            extraData: extraData
        )
    }
}

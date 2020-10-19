//
// Copyright © 2020 Stream.io Inc. All rights reserved.
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
/// Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/StreamChat-SDK-Cheat-Sheet#working-with-extra-data).
///
public typealias CurrentChatUser = _CurrentChatUser<DefaultExtraData.User>

/// A type representing the currently logged-in user. `_CurrentChatUser` is an immutable snapshot of a current user entity at
/// the given time.
///
/// - Note: `_CurrentChatUser` type is not meant to be used directly. If you're using default extra data, use `CurrentChatUser`
/// typealias instead. If you're using custom extra data, create your own typealias of `CurrentChatUser`.
///
/// Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/StreamChat-SDK-Cheat-Sheet#working-with-extra-data).
///
@dynamicMemberLookup
public struct _CurrentChatUser<ExtraData: UserExtraData> {
    /// A list of devices associcated with the user.
    public let devices: [Device]
    
    /// The current device of the user. `nil` if no current device is assigned.
    public let currentDevice: Device?
    
    /// A set of users muted by the user.
    public let mutedUsers: Set<_ChatUser<ExtraData>>
    
    /// The unread counts for the current user.
    public let unreadCount: UnreadCount
    
    /// The user.
    public let user: _ChatUser<ExtraData>
    
    public init(
        user: _ChatUser<ExtraData>,
        devices: [Device] = [],
        currentDevice: Device? = nil,
        mutedUsers: Set<_ChatUser<ExtraData>> = [],
        unreadCount: UnreadCount = .noUnread
    ) {
        self.user = user
        self.devices = devices
        self.currentDevice = currentDevice
        self.mutedUsers = mutedUsers
        self.unreadCount = unreadCount
    }
}

extension _CurrentChatUser {
    public subscript<T>(dynamicMember keyPath: KeyPath<ExtraData, T>) -> T {
        user.extraData[keyPath: keyPath]
    }
    
    public subscript<T>(dynamicMember keyPath: KeyPath<_ChatUser<ExtraData>, T>) -> T {
        user[keyPath: keyPath]
    }
}


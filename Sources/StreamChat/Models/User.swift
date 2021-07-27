//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// A type representing a chat user. `ChatUser` is an immutable snapshot of a chat user entity at the given time.
///
/// - Note: `ChatUser` is a typealias of `_ChatUser` with default extra data. If you're using custom extra data,
/// create your own typealias of `_ChatUser`.
///
/// Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).
///
public typealias ChatUser = _ChatUser<NoExtraData>

/// A unique identifier of a user.
public typealias UserId = String

/// A unique identifier of team.
public typealias TeamId = String

/// A type representing a chat user. `ChatUser` is an immutable snapshot of a chat user entity at the given time.
///
/// - Note: `_ChatUser` type is not meant to be used directly. If you're using default extra data, use `ChatUser`
/// typealias instead. If you're using custom extra data, create your own typealias of `_ChatUser`.
///
/// Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).
///
@dynamicMemberLookup
public class _ChatUser<ExtraData: UserExtraData> {
    /// The unique identifier of the user.
    public let id: UserId
    
    /// Name for this user.
    public let name: String?
    
    /// Image (avatar) url for this user.
    public let imageURL: URL?
    
    /// An indicator whether the user is online.
    public let isOnline: Bool
    
    /// An indicator whether the user is banned.
    public let isBanned: Bool
    
    /// An indicator whether the user is flagged by the current user.
    ///
    /// - Note: Please be aware that the value of this field is not persisted on the server,
    /// and is valid only locally for the current session.
    public let isFlaggedByCurrentUser: Bool
    
    /// The role of the user.
    public let userRole: UserRole
    
    /// The date the user was created.
    public let userCreatedAt: Date
    
    /// The date the user info was updated the last time.
    public let userUpdatedAt: Date
    
    /// The date the user was last time active.
    public let lastActiveAt: Date?
    
    /// Teams the user belongs to.
    ///
    /// You need to enable multi-tenancy if you want to use this, else it'll be empty. Refer to
    /// [docs](https://getstream.io/chat/docs/multi_tenant_chat/?language=swift) for more info.
    public let teams: Set<TeamId>
    
    /// Custom additional data of the user object. You can modify it by setting your custom `ExtraData` type.
    ///
    /// Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).
    ///
    public let extraData: ExtraData

    public let extraDataMap: [String: Any]

    init(
        id: UserId,
        name: String?,
        imageURL: URL?,
        isOnline: Bool,
        isBanned: Bool,
        isFlaggedByCurrentUser: Bool,
        userRole: UserRole,
        createdAt: Date,
        updatedAt: Date,
        lastActiveAt: Date?,
        teams: Set<TeamId>,
        extraData: ExtraData,
        extraDataMap: [String: Any]
    ) {
        self.id = id
        self.name = name
        self.imageURL = imageURL
        self.isOnline = isOnline
        self.isBanned = isBanned
        self.isFlaggedByCurrentUser = isFlaggedByCurrentUser
        self.userRole = userRole
        userCreatedAt = createdAt
        userUpdatedAt = updatedAt
        self.lastActiveAt = lastActiveAt
        self.teams = teams
        self.extraData = extraData
        self.extraDataMap = extraDataMap
    }
}

extension _ChatUser: Hashable {
    public static func == (lhs: _ChatUser<ExtraData>, rhs: _ChatUser<ExtraData>) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension _ChatUser {
    public subscript<T>(dynamicMember keyPath: KeyPath<ExtraData, T>) -> T {
        extraData[keyPath: keyPath]
    }
}

public enum UserRole: String, Codable, Hashable {
    /// This is the default role assigned to any user.
    case user
    
    /// This role allows users to perform more advanced actions. This role should be granted only to staff users
    case admin
    
    /// A user that connected using guest user authentication.
    case guest
    
    /// A user that connected using anonymous authentication.
    case anonymous
}

/// You need to make your custom type conforming to this protocol if you want to use it for extending `ChatUser` entity with your
/// custom additional data.
///
/// Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).
///
public protocol UserExtraData: ExtraData {}

//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// A unique identifier of a user.
public typealias UserId = String

/// A unique identifier of team.
public typealias TeamId = String

/// A type representing a chat user. `ChatUser` is an immutable snapshot of a chat user entity at the given time.
///
public class ChatUser {
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
    
    public let extraData: [String: RawJSON]

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
        extraData: [String: RawJSON]
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
    }
}

extension ChatUser: Hashable {
    public static func == (lhs: ChatUser, rhs: ChatUser) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

public enum UserRole: RawRepresentable, Codable, Hashable, CaseIterable {
    public typealias RawValue = String

    public static var allCases: [UserRole] = [
        .admin, .anonymous, .guest, .user
    ]

    static var builtinRoles: [String: UserRole] = {
        UserRole.allCases.reduce(into: [String: UserRole]()) {
            $0[$1.rawValue] = $1
        }
    }()

    public var rawValue: String {
        switch self {
        case .user: return "user"
        case .admin: return "admin"
        case .guest: return "guest"
        case .anonymous: return "anonymous"
        case let .custom(value):
            return value
        }
    }

    public init(rawValue: String) {
        if let role = UserRole.builtinRoles[rawValue] {
            self = role
        } else {
            self = .custom(rawValue)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        self.init(rawValue: value)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
    
    /// This is the default role assigned to any user.
    case user
    
    /// This role allows users to perform more advanced actions. This role should be granted only to staff users
    case admin
    
    /// A user that connected using guest user authentication.
    case guest
    
    /// A user that connected using anonymous authentication.
    case anonymous

    /// A user with a custom role
    case custom(String)
}

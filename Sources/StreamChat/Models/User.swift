//
// Copyright © 2025 Stream.io Inc. All rights reserved.
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
    public var name: String?

    /// Image (avatar) url for this user.
    public var imageURL: URL?

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
    
    /// The role of the user in different teams.
    public let teamsRole: [String: UserRole]?

    /// The date the user was created.
    public let userCreatedAt: Date

    /// The date the user info was updated the last time.
    public let userUpdatedAt: Date

    /// The date the user was deactivated
    public let userDeactivatedAt: Date?

    /// The date the user was last time active.
    public let lastActiveAt: Date?

    /// Determines if the user has been deactivated
    public var isDeactivated: Bool {
        userDeactivatedAt != nil
    }

    /// Teams the user belongs to.
    ///
    /// You need to enable multi-tenancy if you want to use this, else it'll be empty. Refer to
    /// [docs](https://getstream.io/chat/docs/multi_tenant_chat/?language=swift) for more info.
    public let teams: Set<TeamId>

    /// The language code of the user.
    public let language: TranslationLanguage?
    
    /// Returns the average time (in seconds) the user took to respond to the last message in the channel.
    public let avgResponseTime: Int?

    /// Any additional custom data associated with the user.
    public let extraData: [String: RawJSON]

    init(
        id: UserId,
        name: String?,
        imageURL: URL?,
        isOnline: Bool,
        isBanned: Bool,
        isFlaggedByCurrentUser: Bool,
        userRole: UserRole,
        teamsRole: [String: UserRole]?,
        createdAt: Date,
        updatedAt: Date,
        deactivatedAt: Date?,
        lastActiveAt: Date?,
        teams: Set<TeamId>,
        language: TranslationLanguage?,
        avgResponseTime: Int?,
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
        userDeactivatedAt = deactivatedAt
        self.lastActiveAt = lastActiveAt
        self.teams = teams
        self.language = language
        self.extraData = extraData
        self.teamsRole = teamsRole
        self.avgResponseTime = avgResponseTime
    }
}

extension ChatUser: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension ChatUser: Equatable {
    public static func == (lhs: ChatUser, rhs: ChatUser) -> Bool {
        lhs.id == rhs.id
            && lhs.name == rhs.name
            && lhs.imageURL == rhs.imageURL
            && lhs.isOnline == rhs.isOnline
            && lhs.isBanned == rhs.isBanned
            && lhs.isFlaggedByCurrentUser == rhs.isFlaggedByCurrentUser
            && lhs.userRole == rhs.userRole
            && lhs.teamsRole == rhs.teamsRole
            && lhs.userCreatedAt == rhs.userCreatedAt
            && lhs.userDeactivatedAt == rhs.userDeactivatedAt
            && lhs.lastActiveAt == rhs.lastActiveAt
            && lhs.teams == rhs.teams
            && lhs.avgResponseTime == rhs.avgResponseTime
            && lhs.extraData == rhs.extraData
    }
}

public struct UserRole: RawRepresentable, Codable, Hashable, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
}

public extension UserRole {
    /// This is the default role assigned to any user.
    static let user = Self(rawValue: "user")

    /// This role allows users to perform more advanced actions. This role should be granted only to staff users
    static let admin = Self(rawValue: "admin")

    /// A user that connected using guest user authentication.
    static let guest = Self(rawValue: "guest")

    /// A user that connected using anonymous authentication.
    static let anonymous = Self(rawValue: "anonymous")

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        switch value {
        case "user":
            self = .user
        case "guest":
            self = .guest
        case "admin":
            self = .admin
        case "anonymous":
            self = .anonymous
        default:
            self = .init(rawValue: value)
        }
    }
}

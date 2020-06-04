//
//  User.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 01/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

/// A user.
public struct User: Codable {
    private enum CodingKeys: String, CodingKey {
        case id
        case role
        case name
        case avatarURL = "image"
        case isOnline = "online"
        case isBanned = "banned"
        case created = "created_at"
        case updated = "updated_at"
        case lastActiveDate = "last_active"
        case isInvisible = "invisible"
        case devices
        case mutedUsers = "mutes"
        case unreadMessagesCount = "unread_count"
        case unreadChannelsCount = "unread_channels"
        case isAnonymous = "anon"
        case teams
    }
    
    public enum Role: String, Codable {
        /// A regular user.
        case user
        /// An administrator.
        case admin
        /// A guest.
        case guest
        /// An anonymous.
        case anonymous
    }
    
    /// A custom extra data type for users.
    /// - Note: Use this variable to setup your own extra data type for decoding users custom fields from JSON data.
    public static var extraDataType: UserExtraDataCodable.Type = UserExtraData.self
    
    /// An unkown user.
    @available(*, deprecated, message: """
    Unknown user is not used anymore. By default the current Client user is anonymous (you can check this with `isAnonymous`).
    Anyway you can't connect without `set(user:token)` or `setGuestUser(...)` or `setAnonymousUser(...)`.
    """)
    public static let unknown = User(id: "unknown_\(UUID().uuidString)")
    
    /// Checks if the user is unknown.
    @available(*, deprecated, message: """
    Unknown user is not used anymore. By default the current Client user is anonymous (you can check this with `isAnonymous`).
    Anyway you can't connect without `set(user:token)` or `setGuestUser(...)` or `setAnonymousUser(...)`.
    """)
    public var isUnknown: Bool { self == User.unknown }
    
    /// An anonymous user.
    public static let anonymous = User(id: UUID().uuidString, role: .anonymous)
    /// Checks if the user is anonymous.
    public var isAnonymous: Bool { role == .anonymous }
    
    static var flaggedUsers = Set<User>()
    
    /// A user id.
    public let id: String
    /// A created date.
    public let created: Date
    /// An updated date.
    public let updated: Date
    /// A last active date.
    public let lastActiveDate: Date?
    /// An indicator if a user is online.
    public let isOnline: Bool
    /// An indicator if a user is invisible.
    public let isInvisible: Bool
    /// An indicator if a user was banned.
    public internal(set) var isBanned: Bool
    /// A user role.
    public let role: Role
    /// An extra data for the user.
    public private(set) var extraData: UserExtraDataCodable?
    /// A list of devices.
    public internal(set) var devices: [Device]
    /// A list of devices.
    public internal(set) var currentDevice: Device?
    /// Muted users.
    public internal(set) var mutedUsers: [MutedUser]
    /// Teams the user belongs to. You need to enable multi-tenancy if you want to use this, else it'll be empty.
    /// Refer to [docs](https://getstream.io/chat/docs/multi_tenant_chat/?language=swift) for more info.
    public let teams: [String]
    /// Check if the user is the current user.
    public var isCurrent: Bool { self == Client.shared.user }
    /// The current user.
    public static var current: User { Client.shared.user }
    /// Checks if the user can be muted.
    public var canBeMuted: Bool { !isCurrent }
    /// Checks if the user is muted.
    public var isMuted: Bool { isCurrent ? false : Client.shared.user.isMuted(user: self) }
    /// Returns the user as a member.
    public var asMember: Member { Member(self) }
    /// Checks if the user is flagged (locally).
    public var isFlagged: Bool { User.flaggedUsers.contains(self) }
    
    let unreadCount: UnreadCount
    
    /// Init a user.
    /// - Parameters:
    ///   - id: a user id.
    ///   - role: a user role (see `User.Role`).
    ///   - extraData: an extra data for the user.
    ///   - created: a created date. It will be updated form server.
    ///   - updated: a updated date. It will be updated form server.
    ///   - lastActiveDate: a last active date. It will be updated form server.
    ///   - isInvisible: makes user invisible.
    ///   - isBanned: it will be updated form server.
    ///   - mutedUsers: it will be updated form server.
    ///   - teams: The teams the user belongs to.
    public init(id: String,
                role: Role = .user,
                extraData: UserExtraDataCodable? = nil,
                created: Date = .init(),
                updated: Date = .init(),
                lastActiveDate: Date? = nil,
                isInvisible: Bool = false,
                isBanned: Bool = false,
                mutedUsers: [MutedUser] = [],
                teams: [String] = []) {
        self.id = id
        self.role = role
        self.extraData = extraData
        self.created = created
        self.updated = updated
        self.lastActiveDate = lastActiveDate
        self.isInvisible = isInvisible
        self.isBanned = isBanned
        self.mutedUsers = mutedUsers
        self.teams = teams
        isOnline = false
        unreadCount = .noUnread
        devices = []
    }
    
    init(id: String, role: Role = .user, name: String, avatarURL: URL? = nil, extraData: UserExtraDataCodable? = nil) {
        self.init(id: id, role: role, extraData: extraData)
        self.name = name
        self.avatarURL = avatarURL
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        role = try container.decode(Role.self, forKey: .role)
        created = try container.decode(Date.self, forKey: .created)
        updated = try container.decode(Date.self, forKey: .updated)
        lastActiveDate = try container.decodeIfPresent(Date.self, forKey: .lastActiveDate)
        isOnline = try container.decode(Bool.self, forKey: .isOnline)
        isInvisible = try container.decodeIfPresent(Bool.self, forKey: .isInvisible) ?? false
        isBanned = try container.decodeIfPresent(Bool.self, forKey: .isBanned) ?? false
        devices = try container.decodeIfPresent([Device].self, forKey: .devices) ?? []
        mutedUsers = try container.decodeIfPresent([MutedUser].self, forKey: .mutedUsers) ?? []
        teams = try container.decodeIfPresent([String].self, forKey: .teams) ?? []
        extraData = User.decodeUserExtraData(from: decoder)
        
        let unreadChannelsCount = try container.decodeIfPresent(Int.self, forKey: .unreadChannelsCount) ?? 0
        let unreadMessagesCount = try container.decodeIfPresent(Int.self, forKey: .unreadMessagesCount) ?? 0
        unreadCount = UnreadCount(channels: unreadChannelsCount, messages: unreadMessagesCount)
    }
    
    /// Safely decode user extra data and if it fail try to decode only default properties: name, avatarURL.
    private static func decodeUserExtraData(from decoder: Decoder) -> UserExtraDataCodable? {
        do {
            var extraData = try Self.extraDataType.init(from: decoder) // swiftlint:disable:this explicit_init
            extraData.avatarURL = extraData.avatarURL?.removingRandomSVG()
            return extraData
            
        } catch {
            ClientLogger.log("🐴❌", level: .error, "User extra data decoding error: \(error). "
                + "Trying to recover by only decoding name and imageURL")
            
            guard let container = try? decoder.container(keyedBy: CodingKeys.self) else {
                return nil
            }
            
            // Recovering the default user extra data properties: name, avatarURL.
            var extraData = UserExtraData()
            extraData.name = try? container.decodeIfPresent(String.self, forKey: .name)
            extraData.avatarURL = try? container.decodeIfPresent(URL.self, forKey: .avatarURL)?.removingRandomSVG()
            return extraData
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        extraData?.encodeSafely(to: encoder, logMessage: "📦 when encoding a user extra data")
        
        if isInvisible {
            try container.encode(isInvisible, forKey: .isInvisible)
        }
        
        if isAnonymous {
            try container.encode(true, forKey: .isAnonymous)
        }
    }
    
    func isMuted(user: User) -> Bool {
        mutedUsers.contains { $0.user == user }
    }
}

extension User: Hashable {
    
    public static func == (lhs: User, rhs: User) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: UserExtraDataCodable

extension User {
    
    /// User display name.
    public var name: String {
        get {
            extraData?.name ?? id
        }
        set {
            var object: UserExtraDataCodable = extraData ?? UserExtraData()
            object.name = newValue
            extraData = object
        }
    }
    
    /// Avatar image URL for the user.
    public var avatarURL: URL? {
        get {
            extraData?.avatarURL
        }
        set {
            var object: UserExtraDataCodable = extraData ?? UserExtraData()
            object.avatarURL = newValue
            extraData = object
        }
    }
}

// MARK: - Supporting Structs

/// A response with a list of users.
public struct UsersResponse: Decodable {
    /// A list of users.
    public let users: [User]
}

/// A response with a list of users by id.
public struct UpdatedUsersResponse: Decodable {
    /// A list of users by Id.
    public let users: [String: User]
}

/// A response with a list of devices.
public struct DevicesResponse: Decodable {
    /// A list of devices.
    public let devices: [Device]
}

/// A request object to ban a user.
public struct UserBan: Encodable {
    private enum CodingKeys: String, CodingKey {
        case userId = "target_user_id"
        case channelType = "type"
        case channelId = "id"
        case timeoutInMinutes = "timeout"
        case reason
    }
    
    let userId: String
    let channelType: ChannelType
    let channelId: String
    let timeoutInMinutes: Int?
    let reason: String?
    
    init(user: User, channel: Channel, timeoutInMinutes: Int?, reason: String?) {
        userId = user.id
        channelType = channel.type
        channelId = channel.id
        self.timeoutInMinutes = timeoutInMinutes
        self.reason = reason
    }
}

/// A flag message response.
public struct FlagUserResponse: Decodable {
    private enum CodingKeys: String, CodingKey {
        case user = "target_user"
        case created = "created_at"
        case updated = "updated_at"
    }
    
    /// A flagged user.
    public let user: User
    /// A created date.
    public let created: Date
    /// A updated date.
    public let updated: Date
}

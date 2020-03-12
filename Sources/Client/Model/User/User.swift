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
        case name
        case avatarURL = "image"
        case role
        case isOnline = "online"
        case isBanned = "banned"
        case created = "created_at"
        case updated = "updated_at"
        case lastActiveDate = "last_active"
        case isInvisible = "invisible"
        case devices
        case mutedUsers = "mutes"
        case messagesUnreadCount = "unread_count"
        case channelsUnreadCount = "unread_channels"
        case isAnonymous = "anon"
    }
    
    /// An unkown user.
    public static let unknown: User = {
        let id = UUID().uuidString
        return User(id: "unknown_\(id)", name: "Unknown \(id.prefix(4))")
    }()
    
    /// Checks if the user is unknown.
    public var isUnknown: Bool { self == User.unknown }
    
    /// An anonymous user.
    public static let anonymous = User(id: UUID().uuidString, name: "", role: .anonymous)
    
    static var flaggedUsers = Set<User>()
    
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
    
    /// A user id.
    public let id: String
    /// A user name.
    public let name: String
    /// An avatar URL.
    public var avatarURL: URL?
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
    public let extraData: ExtraData?
    /// A list of devices.
    public internal(set) var devices: [Device]
    /// A list of devices.
    public internal(set) var currentDevice: Device?
    /// Muted users.
    public internal(set) var mutedUsers: [MutedUser]
    
    /// Channels and messages unread counts.
    public var unreadCount: UnreadCount { unreadCountAtomic.get(default: .noUnread) }
    let unreadCountAtomic = Atomic<UnreadCount>(.noUnread) { _, _ in Client.shared.onUserUpdate?(User.current) }
    
    /// Check if the user is the current user.
    public var isCurrent: Bool { self == Client.shared.user }
    /// The current user.
    public static var current: User { Client.shared.user }
    /// Checks if the user can be muted.
    public var canBeMuted: Bool { !isCurrent }
    /// Checks if the user is muted.
    public var isMuted: Bool { isCurrent ? false : Client.shared.user.mutedUsers.first(where: { $0.user == self }) != nil }
    /// Returns the user as a member.
    public var asMember: Member { Member(self) }
    /// Checks if the user is flagged (locally).
    public var isFlagged: Bool { User.flaggedUsers.contains(self) }
    
    public var isAnonymous: Bool {
        if case .anonymous = role {
            return true
        }
        
        return false
    }
    
    /// Init a user.
    /// - Parameters:
    ///   - id: a user id.
    ///   - name: a user name. Name comes from server when argument is empty string.
    ///   - role: a user role (see `User.Role`).
    ///   - avatarURL: a user avatar.
    ///   - created: a created date. It will be updated form server.
    ///   - updated: a updated date. It will be updated form server.
    ///   - lastActiveDate: a last active date. It will be updated form server.
    ///   - isInvisible: makes user invisible.
    ///   - isBanned: it will be updated form server.
    ///   - mutedUsers: it will be updated form server.
    ///   - extraData: an extra data for the user.
    public init(id: String,
                name: String = "",
                role: Role = .user,
                avatarURL: URL? = nil,
                extraData: Codable? = nil,
                created: Date = .init(),
                updated: Date = .init(),
                lastActiveDate: Date? = nil,
                isInvisible: Bool = false,
                isBanned: Bool = false,
                mutedUsers: [MutedUser] = []) {
        self.id = id
        self.name = name
        self.role = role
        self.avatarURL = avatarURL
        self.extraData = ExtraData(extraData)
        self.created = created
        self.updated = updated
        self.lastActiveDate = lastActiveDate
        self.isInvisible = isInvisible
        self.isBanned = isBanned
        self.mutedUsers = mutedUsers
        isOnline = false
        devices = []
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
        extraData = ExtraData(ExtraData.decodableTypes.first(where: { $0.isUser })?.decode(from: decoder))
        
        if let name = try? container.decodeIfPresent(String.self, forKey: .name) {
            self.name = name
        } else {
            name = id
        }
        
        if let avatarURL = try? container.decodeIfPresent(URL.self, forKey: .avatarURL),
           !avatarURL.absoluteString.contains("random_svg") {
            self.avatarURL = avatarURL
        } else {
            avatarURL = nil
        }
        
        let channelsUnreadCount = try container.decodeIfPresent(Int.self, forKey: .channelsUnreadCount) ?? 0
        let messagesUnreadCount = try container.decodeIfPresent(Int.self, forKey: .messagesUnreadCount) ?? 0
        unreadCountAtomic.set(UnreadCount(channels: channelsUnreadCount, messages: messagesUnreadCount))
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(avatarURL, forKey: .avatarURL)
        extraData?.encodeSafely(to: encoder, logMessage: "📦 when encoding a user extra data")
        
        if !name.isBlank {
            try container.encode(name, forKey: .name)
        }
        
        if isInvisible {
            try container.encode(isInvisible, forKey: .isInvisible)
        }
        
        if isAnonymous {
            try container.encode(true, forKey: .isAnonymous)
        }
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

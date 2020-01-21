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
    }
    
    /// An unkown user.
    public static let tempDevelopmentUser: User = {
        let salt = Int.random(in: 1000...9999)
        return User(id: "temp_dev_user_\(salt)", name: "User \(salt)")
    }()
    
    static var flaggedUsers = Set<User>()
    
    public enum Role: String, Codable {
        case user
        case admin
        case guest
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
    let messagesUnreadCount: Int
    let channelsUnreadCount: Int
    
    /// Check if the user is the current user.
    public var isCurrent: Bool {
        return self == Client.shared.user
    }
    
    /// The current user.
    public static var current: User {
        return Client.shared.user
    }
    
    /// Checks if the user can be muted.
    public var canBeMuted: Bool {
        return !isCurrent
    }
    
    /// Checks if the user is muted.
    public var isMuted: Bool {
        return isCurrent ? false : Client.shared.user.mutedUsers.first(where: { $0.user == self }) != nil
    }
    
    /// Returns the user as a member.
    public var asMember: Member {
        return Member(self)
    }
    
    /// Checks if the user is flagged (locally).
    var isFlagged: Bool {
        return User.flaggedUsers.contains(self)
    }
    
    /// Init a user.
    ///
    /// - Parameters:
    ///     - id: a user id.
    ///     - name: a user name.
    ///     - an avatar URL.
    public init(id: String,
                name: String,
                role: Role = .user,
                avatarURL: URL? = nil,
                created: Date = .default,
                updated: Date = .default,
                lastActiveDate: Date? = nil,
                isInvisible: Bool = false,
                isBanned: Bool = false,
                mutedUsers: [MutedUser] = [],
                extraData: Codable? = nil) {
        self.id = id
        self.name = name
        self.avatarURL = avatarURL
        self.role = role
        self.created = created
        self.updated = updated
        self.lastActiveDate = lastActiveDate
        isOnline = false
        self.isInvisible = isInvisible
        self.isBanned = isBanned
        self.mutedUsers = mutedUsers
        messagesUnreadCount = 0
        channelsUnreadCount = 0
        devices = []
        self.extraData = ExtraData(extraData)
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
        messagesUnreadCount = try container.decodeIfPresent(Int.self, forKey: .messagesUnreadCount) ?? 0
        channelsUnreadCount = try container.decodeIfPresent(Int.self, forKey: .channelsUnreadCount) ?? 0
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
    }
}

extension User: Hashable {
    
    public static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id
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

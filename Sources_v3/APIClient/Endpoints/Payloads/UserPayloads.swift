//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

private enum UserPayloadsCodingKeys: String, CodingKey {
    case id
    case role
    case name
    case avatarURL = "image"
    case isOnline = "online"
    case isBanned = "banned"
    case createdAt = "created_at"
    case updatedAt = "updated_at"
    case lastActiveAt = "last_active"
    case isInvisible = "invisible"
    case teams
    case unreadChannelsCount = "unread_channels"
    case unreadMessagesCount = "total_unread_count"
}

/// An object describing the incoming user JSON payload.
class UserPayload<ExtraData: UserExtraData>: Decodable {
    let id: String
    let role: UserRole
    let createdAt: Date
    let updatedAt: Date
    let lastActiveAt: Date?
    let isOnline: Bool
    let isInvisible: Bool
    let isBanned: Bool
    let teams: [String]
    let extraData: ExtraData
    
    init(id: String,
         role: UserRole,
         createdAt: Date,
         updatedAt: Date,
         lastActiveAt: Date?,
         isOnline: Bool,
         isInvisible: Bool,
         isBanned: Bool,
         teams: [String] = [],
         extraData: ExtraData) {
        self.id = id
        self.role = role
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastActiveAt = lastActiveAt
        self.isOnline = isOnline
        self.isInvisible = isInvisible
        self.isBanned = isBanned
        self.teams = teams
        self.extraData = extraData
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: UserPayloadsCodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        role = try container.decode(UserRole.self, forKey: .role)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        lastActiveAt = try container.decodeIfPresent(Date.self, forKey: .lastActiveAt)
        isOnline = try container.decode(Bool.self, forKey: .isOnline)
        isInvisible = try container.decodeIfPresent(Bool.self, forKey: .isInvisible) ?? false
        isBanned = try container.decodeIfPresent(Bool.self, forKey: .isBanned) ?? false
        teams = try container.decodeIfPresent([String].self, forKey: .teams) ?? []
        extraData = try ExtraData(from: decoder)
    }
}

/// An object describing the outgoing user JSON payload.
class UserRequestBody<ExtraData: UserExtraData>: Encodable {
    let id: String
    let extraData: ExtraData
    
    init(id: String, extraData: ExtraData) {
        self.id = id
        self.extraData = extraData
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: UserPayloadsCodingKeys.self)
        try container.encode(id, forKey: .id)
        try extraData.encode(to: encoder)
    }
}

// TODO: Muted user

class CurrentUserPayload<ExtraData: UserExtraData>: UserPayload<ExtraData> {
    private enum CodingKeys: String, CodingKey {
        case mutedUsers = "mutes"
        case isAnonymous = "anon"
        case devices
    }
    
    /// A list of devices.
    let devices: [Device]
    /// Muted users.
    let mutedUsers: [MutedUser<ExtraData>]
    
    init(id: String,
         role: UserRole,
         createdAt: Date,
         updatedAt: Date,
         lastActiveAt: Date?,
         isOnline: Bool,
         isInvisible: Bool,
         isBanned: Bool,
         teams: [String] = [],
         extraData: ExtraData,
         devices: [Device] = [],
         mutedUsers: [MutedUser<ExtraData>] = []) {
        self.devices = devices
        self.mutedUsers = mutedUsers
        
        super.init(id: id,
                   role: role,
                   createdAt: createdAt,
                   updatedAt: updatedAt,
                   lastActiveAt: lastActiveAt,
                   isOnline: isOnline,
                   isInvisible: isInvisible,
                   isBanned: isBanned,
                   teams: teams,
                   extraData: extraData)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        devices = try container.decodeIfPresent([Device].self, forKey: .devices) ?? []
        mutedUsers = try container.decodeIfPresent([MutedUser<ExtraData>].self, forKey: .mutedUsers) ?? []
        
        try super.init(from: decoder)
    }
}

/// A muted user.
struct MutedUser<ExtraData: UserExtraData>: Decodable {
    private enum CodingKeys: String, CodingKey {
        case user = "target"
        case created = "created_at"
        case updated = "updated_at"
    }
    
    /// A muted user.
    public let user: UserPayload<ExtraData>
    /// A created date.
    public let created: Date
    /// A updated date.
    public let updated: Date
    
    /// Create a muted user for a database.
    /// - Parameters:
    ///   - user: a user.
    ///   - created: a created date.
    ///   - updated: an updated date.
    init(user: UserPayload<ExtraData>, created: Date, updated: Date) {
        self.user = user
        self.created = created
        self.updated = updated
    }
}

/// A muted users response.
struct MutedUsersResponse<ExtraData: UserExtraData>: Decodable {
    private enum CodingKeys: String, CodingKey {
        case mutedUser = "mute"
        case currentUser = "own_user"
    }
    
    /// A muted user.
    public let mutedUser: MutedUser<ExtraData>
    /// The current user.
    public let currentUser: UserPayload<ExtraData>
}

//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

class UserPayload<ExtraData: UserExtraData>: Decodable {
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
        case isAnonymous = "anon"
        case teams
    }
    
    /// A user id.
    let id: String
    /// A created date.
    let created: Date
    /// An updated date.
    let updated: Date
    /// A last active date.
    let lastActiveDate: Date?
    /// An indicator if a user is online.
    let isOnline: Bool
    /// An indicator if a user is invisible.
    let isInvisible: Bool
    /// An indicator if a user was banned.
    let isBanned: Bool
    /// A user role.
    let roleRawValue: String
    /// An extra data for the user.
    let extraData: ExtraData
    
    let teams: [String]
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        roleRawValue = try container.decode(String.self, forKey: .role)
        created = try container.decode(Date.self, forKey: .created)
        updated = try container.decode(Date.self, forKey: .updated)
        lastActiveDate = try container.decodeIfPresent(Date.self, forKey: .lastActiveDate)
        isOnline = try container.decode(Bool.self, forKey: .isOnline)
        isInvisible = try container.decodeIfPresent(Bool.self, forKey: .isInvisible) ?? false
        isBanned = try container.decodeIfPresent(Bool.self, forKey: .isBanned) ?? false
        teams = try container.decodeIfPresent([String].self, forKey: .teams) ?? []
        extraData = try ExtraData(from: decoder)
    }
    
    init(
        id: String, created: Date, updated: Date, lastActiveDate: Date?, isOnline: Bool, isInvisible: Bool, isBanned: Bool,
        roleRawValue: String, extraData: ExtraData, teams: [String]
    ) {
        self.id = id
        self.created = created
        self.updated = updated
        self.lastActiveDate = lastActiveDate
        self.isOnline = isOnline
        self.isInvisible = isInvisible
        self.isBanned = isBanned
        self.roleRawValue = roleRawValue
        self.extraData = extraData
        self.teams = teams
    }
}

// TODO: Muted user

class CurrentUserPayload<ExtraData: UserExtraData>: UserPayload<ExtraData> {
    internal init(
        id: String, created: Date, updated: Date, lastActiveDate: Date?, isOnline: Bool, isInvisible: Bool, isBanned: Bool,
        roleRawValue: String, extraData: ExtraData, teams: [String], devices: [Device], mutedUsers: [MutedUser<ExtraData>],
        unreadChannelsCount: Int?, unreadMessagesCount: Int?
    ) {
        self.devices = devices
        self.mutedUsers = mutedUsers
        self.unreadChannelsCount = unreadChannelsCount
        self.unreadMessagesCount = unreadMessagesCount
        
        super.init(id: id, created: created, updated: updated, lastActiveDate: lastActiveDate, isOnline: isOnline,
                   isInvisible: isInvisible, isBanned: isBanned, roleRawValue: roleRawValue, extraData: extraData, teams: teams)
    }
    
    private enum CodingKeys: String, CodingKey {
        case mutedUsers = "mutes"
        case unreadMessagesCount = "unread_count"
        case unreadChannelsCount = "unread_channels"
        case isAnonymous = "anon"
        case devices
    }
    
    /// A list of devices.
    public let devices: [Device]
    /// Muted users.
    public let mutedUsers: [MutedUser<ExtraData>]
    
    public let unreadChannelsCount: Int?
    public let unreadMessagesCount: Int?
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        devices = try container.decodeIfPresent([Device].self, forKey: .devices) ?? []
        mutedUsers = try container.decodeIfPresent([MutedUser<ExtraData>].self, forKey: .mutedUsers) ?? []
        unreadChannelsCount = try container.decodeIfPresent(Int.self, forKey: .unreadChannelsCount)
        unreadMessagesCount = try container.decodeIfPresent(Int.self, forKey: .unreadMessagesCount)
        
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

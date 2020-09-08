//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

enum UserPayloadsCodingKeys: String, CodingKey {
    case id
    case role
    case isOnline = "online"
    case isBanned = "banned"
    case createdAt = "created_at"
    case updatedAt = "updated_at"
    case lastActiveAt = "last_active"
    case isInvisible = "invisible"
    case teams
    case unreadChannelsCount = "unread_channels"
    case unreadMessagesCount = "total_unread_count"
    case mutedUsers = "mutes"
    case isAnonymous = "anon"
    case devices
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
    
    init(
        id: String,
        role: UserRole,
        createdAt: Date,
        updatedAt: Date,
        lastActiveAt: Date?,
        isOnline: Bool,
        isInvisible: Bool,
        isBanned: Bool,
        teams: [String] = [],
        extraData: ExtraData
    ) {
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

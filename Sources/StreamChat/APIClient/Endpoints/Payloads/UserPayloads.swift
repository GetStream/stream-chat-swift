//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

enum UserPayloadsCodingKeys: String, CodingKey, CaseIterable {
    case id
    case name
    case imageURL = "image"
    case role
    case isOnline = "online"
    case isBanned = "banned"
    case createdAt = "created_at"
    case updatedAt = "updated_at"
    case deactivatedAt = "deactivated_at"
    case lastActiveAt = "last_active"
    case isInvisible = "invisible"
    case teams
    case unreadChannelsCount = "unread_channels"
    case unreadMessagesCount = "total_unread_count"
    case unreadThreads = "unread_threads"
    case mutedUsers = "mutes"
    case mutedChannels = "channel_mutes"
    case isAnonymous = "anon"
    case devices
    case unreadCount = "unread_count"
    case language
    case privacySettings = "privacy_settings"
    case blockedUserIds = "blocked_user_ids"
}

// MARK: - GET users

/// An object describing the incoming user JSON payload.
class UserPayload: Decodable {
    let id: String
    let name: String?
    let imageURL: URL?
    let role: UserRole
    let createdAt: Date
    let updatedAt: Date
    let deactivatedAt: Date?
    let lastActiveAt: Date?
    let isOnline: Bool
    let isInvisible: Bool
    let isBanned: Bool
    let teams: [TeamId]
    let language: String?
    let extraData: [String: RawJSON]

    init(
        id: String,
        name: String?,
        imageURL: URL?,
        role: UserRole,
        createdAt: Date,
        updatedAt: Date,
        deactivatedAt: Date?,
        lastActiveAt: Date?,
        isOnline: Bool,
        isInvisible: Bool,
        isBanned: Bool,
        teams: [TeamId] = [],
        language: String?,
        extraData: [String: RawJSON]
    ) {
        self.id = id
        self.name = name
        self.imageURL = imageURL
        self.role = role
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deactivatedAt = deactivatedAt
        self.lastActiveAt = lastActiveAt
        self.isOnline = isOnline
        self.isInvisible = isInvisible
        self.isBanned = isBanned
        self.teams = teams
        self.language = language
        self.extraData = extraData
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: UserPayloadsCodingKeys.self)
        
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? ""
        name = try container.decodeIfPresent(String.self, forKey: .name)
        imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL).flatMap(URL.init(string:))
        role = try container.decode(UserRole.self, forKey: .role)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        deactivatedAt = try container.decodeIfPresent(Date.self, forKey: .deactivatedAt)
        lastActiveAt = try container.decodeIfPresent(Date.self, forKey: .lastActiveAt)
        isOnline = try container.decode(Bool.self, forKey: .isOnline)
        isInvisible = try container.decodeIfPresent(Bool.self, forKey: .isInvisible) ?? false
        isBanned = try container.decodeIfPresent(Bool.self, forKey: .isBanned) ?? false
        teams = try container.decodeIfPresent([String].self, forKey: .teams) ?? []
        language = try container.decodeIfPresent(String.self, forKey: .language)

        do {
            var payload = try [String: RawJSON](from: decoder)
            payload.removeValues(forKeys: UserPayloadsCodingKeys.allCases.map(\.rawValue))
            extraData = payload
        } catch {
            log.error(
                "Failed to decode extra data for User with id: <\(id)>, using default value instead. "
                    + "Error: \(error)"
            )
            extraData = [:]
        }
    }
}

/// An object describing the outgoing user JSON payload.
class UserRequestBody: Encodable {
    let id: String
    let name: String?
    let imageURL: URL?
    let extraData: [String: RawJSON]

    init(id: String, name: String?, imageURL: URL?, extraData: [String: RawJSON]) {
        self.id = id
        self.name = name
        self.imageURL = imageURL
        self.extraData = extraData
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: UserPayloadsCodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(imageURL, forKey: .imageURL)
        try extraData.encode(to: encoder)
    }
}

// MARK: - PATCH users

/// An object describing the incoming user JSON payload.
struct CurrentUserUpdateResponse: Decodable {
    let user: CurrentUserPayload

    enum CodingKeys: String, CodingKey {
        case users
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let users = try container.decode([String: CurrentUserPayload].self, forKey: .users)
        guard let user = users.first?.value else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: [CodingKeys.users], debugDescription: "Missing updated user.")
            )
        }
        self.user = user
    }

    init(user: CurrentUserPayload) {
        self.user = user
    }
}

/// An object describing the outgoing user JSON payload.
struct UserUpdateRequestBody: Encodable {
    let name: String?
    let imageURL: URL?
    let privacySettings: UserPrivacySettingsPayload?
    let role: UserRole?
    let extraData: [String: RawJSON]?

    init(
        name: String?,
        imageURL: URL?,
        privacySettings: UserPrivacySettingsPayload?,
        role: UserRole?,
        extraData: [String: RawJSON]?
    ) {
        self.name = name
        self.imageURL = imageURL
        self.privacySettings = privacySettings
        self.role = role
        self.extraData = extraData
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: UserPayloadsCodingKeys.self)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(imageURL, forKey: .imageURL)
        try container.encodeIfPresent(privacySettings, forKey: .privacySettings)
        try container.encodeIfPresent(role, forKey: .role)
        try extraData?.encode(to: encoder)
    }
}

// MARK: - Current User Unreads

struct CurrentUserUnreadsPayload: Decodable {
    enum CodingKeys: String, CodingKey {
        case totalUnreadCount = "total_unread_count"
        case totalUnreadThreadsCount = "total_unread_threads_count"
        case channels
        case channelType = "channel_type"
        case threads
    }

    let totalUnreadCount: Int
    let totalUnreadThreadsCount: Int
    let channels: [CurrentUserChannelUnreadPayload]
    let channelType: [ChannelUnreadByTypePayload]
    let threads: [CurrentUserThreadUnreadPayload]
}

struct CurrentUserChannelUnreadPayload: Decodable {
    enum CodingKeys: String, CodingKey {
        case channelId = "channel_id"
        case unreadCount = "unread_count"
        case lastRead = "last_read"
    }

    let channelId: ChannelId
    let unreadCount: Int
    let lastRead: Date?
}

struct CurrentUserThreadUnreadPayload: Decodable {
    enum CodingKeys: String, CodingKey {
        case parentMessageId = "parent_message_id"
        case lastRead = "last_read"
        case lastReadMessageId = "last_read_message_id"
        case unreadCount = "unread_count"
    }

    let parentMessageId: MessageId
    let lastRead: Date?
    let lastReadMessageId: MessageId?
    let unreadCount: Int
}

struct ChannelUnreadByTypePayload: Decodable {
    enum CodingKeys: String, CodingKey {
        case channelType = "channel_type"
        case channelCount = "channel_count"
        case unreadCount = "unread_count"
    }

    let channelType: ChannelType
    let channelCount: Int
    let unreadCount: Int
}

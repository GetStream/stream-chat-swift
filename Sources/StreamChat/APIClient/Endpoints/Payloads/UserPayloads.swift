//
// Copyright © 2022 Stream.io Inc. All rights reserved.
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
    case lastActiveAt = "last_active"
    case isInvisible = "invisible"
    case teams
    case unreadChannelsCount = "unread_channels"
    case unreadMessagesCount = "total_unread_count"
    case mutedUsers = "mutes"
    case mutedChannels = "channel_mutes"
    case isAnonymous = "anon"
    case devices
    case unreadCount = "unread_count"
}

// MARK: - GET users

/// An object describing the incoming user JSON payload.
class UserPayload: Decodable {
    static var userDecodingCache = NSCache<NSString, UserPayload>()
    
    let id: String
    let name: String?
    let imageURL: URL?
    let role: UserRole
    let createdAt: Date
    let updatedAt: Date
    let lastActiveAt: Date?
    let isOnline: Bool
    let isInvisible: Bool
    let isBanned: Bool
    let teams: [TeamId]
    let extraData: [String: RawJSON]

    init(
        id: String,
        name: String?,
        imageURL: URL?,
        role: UserRole,
        createdAt: Date,
        updatedAt: Date,
        lastActiveAt: Date?,
        isOnline: Bool,
        isInvisible: Bool,
        isBanned: Bool,
        teams: [TeamId] = [],
        extraData: [String: RawJSON]
    ) {
        self.id = id
        self.name = name
        self.imageURL = imageURL
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
        let userId = try container.decode(String.self, forKey: .id)
        
        id = userId
        // `role` is scope dependent so we don't use the cached value
        role = try container.decode(UserRole.self, forKey: .role)
        // These fields are not always sent in a UserPayload
        // so we can't use the cached values
        lastActiveAt = try container.decodeIfPresent(Date.self, forKey: .lastActiveAt)
        isInvisible = try container.decodeIfPresent(Bool.self, forKey: .isInvisible) ?? false
        isBanned = try container.decodeIfPresent(Bool.self, forKey: .isBanned) ?? false
        teams = try container.decodeIfPresent([String].self, forKey: .teams) ?? []
        
        let isCachingEnabled = decoder.userInfo[JSONDecoder.userPayloadCachingFlagKey] as? Bool ?? false
        
        if isCachingEnabled, let cachedUserPayload = UserPayload.userDecodingCache.object(forKey: userId as NSString) {
            name = cachedUserPayload.name
            imageURL = cachedUserPayload.imageURL
            createdAt = cachedUserPayload.createdAt
            updatedAt = cachedUserPayload.updatedAt
            isOnline = cachedUserPayload.isOnline
            extraData = cachedUserPayload.extraData
        } else {
            name = try container.decodeIfPresent(String.self, forKey: .name)
            imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL).flatMap(URL.init(string:))
            createdAt = try container.decode(Date.self, forKey: .createdAt)
            updatedAt = try container.decode(Date.self, forKey: .updatedAt)
            isOnline = try container.decode(Bool.self, forKey: .isOnline)
            
            do {
                var payload = try [String: RawJSON](from: decoder)
                payload.removeValues(forKeys: UserPayloadsCodingKeys.allCases.map(\.rawValue))
                extraData = payload
            } catch {
                log.error(
                    "Failed to decode extra data for User with id: <\(userId)>, using default value instead. "
                        + "Error: \(error)"
                )
                extraData = [:]
            }
            
            if isCachingEnabled {
                UserPayload.userDecodingCache.setObject(self, forKey: userId as NSString)
            }
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
struct UserUpdateResponse: Decodable {
    let user: UserPayload
    
    enum CodingKeys: String, CodingKey {
        case users
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let users = try container.decode([String: UserPayload].self, forKey: .users)
        guard let user = users.first?.value else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: [CodingKeys.users], debugDescription: "Missing updated user.")
            )
        }
        self.user = user
    }
    
    init(user: UserPayload) {
        self.user = user
    }
}

/// An object describing the outgoing user JSON payload.
struct UserUpdateRequestBody: Encodable {
    let name: String?
    let imageURL: URL?
    let extraData: [String: RawJSON]?
    
    init(name: String? = nil, imageURL: URL? = nil, extraData: [String: RawJSON]? = nil) {
        self.name = name
        self.imageURL = imageURL
        self.extraData = extraData
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: UserPayloadsCodingKeys.self)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(imageURL, forKey: .imageURL)
        try extraData?.encode(to: encoder)
    }
}

//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

enum UserPayloadsCodingKeys: String, CodingKey {
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
    case isAnonymous = "anon"
    case devices
}

// MARK: - GET users

/// An object describing the incoming user JSON payload.
class UserPayload<ExtraData: UserExtraData>: Decodable, ChangeHashable {
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
    let teams: [String]
    let extraData: ExtraData
    
    var hasher: ChangeHasher {
        UserHasher(
            id: id,
            name: name,
            imageURL: imageURL,
            role: role.rawValue,
            createdAt: createdAt,
            updatedAt: updatedAt,
            lastActiveAt: lastActiveAt,
            isOnline: isOnline,
            isBanned: isBanned,
            extraData: (try? JSONEncoder.default.encode(extraData)) ?? .init()
        )
    }
    
    // This needs to be explicit so we can override it in
    // `UserDTO_Tests.test_DTO_skipsUnnecessarySave`
    var changeHash: Int {
        hasher.changeHash
    }
    
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
        teams: [String] = [],
        extraData: ExtraData
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
        id = try container.decode(String.self, forKey: .id)
        // Unfortunately, the built-in URL decoder fails, if the string is empty. We need to
        // provide custom decoding to handle URL? as expected.
        name = try container.decodeIfPresent(String.self, forKey: .name)
        imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL).flatMap(URL.init(string:))
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
    let name: String?
    let imageURL: URL?
    let extraData: ExtraData
    
    init(id: String, name: String?, imageURL: URL?, extraData: ExtraData) {
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
struct UserUpdateResponse<ExtraData: UserExtraData>: Decodable {
    let user: UserPayload<ExtraData>
    
    enum CodingKeys: String, CodingKey {
        case users
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let users = try container.decode([String: UserPayload<ExtraData>].self, forKey: .users)
        guard let user = users.first?.value else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: [CodingKeys.users], debugDescription: "Missing updated user.")
            )
        }
        self.user = user
    }
    
    init(user: UserPayload<ExtraData>) {
        self.user = user
    }
}

/// An object describing the outgoing user JSON payload.
struct UserUpdateRequestBody<ExtraData: UserExtraData>: Encodable {
    let name: String?
    let imageURL: URL?
    let extraData: ExtraData?
    
    init(name: String? = nil, imageURL: URL? = nil, extraData: ExtraData? = nil) {
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

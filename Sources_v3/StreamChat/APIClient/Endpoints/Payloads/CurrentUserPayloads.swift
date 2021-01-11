//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// An object describing the incoming current user JSON payload.
class CurrentUserPayload<ExtraData: UserExtraData>: UserPayload<ExtraData> {
    /// A list of devices.
    let devices: [DevicePayload]
    /// Muted users.
    let mutedUsers: [MutedUserPayload<ExtraData>]
    /// Unread channel and message counts
    let unreadCount: UnreadCount?
    
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
        extraData: ExtraData,
        devices: [DevicePayload] = [],
        mutedUsers: [MutedUserPayload<ExtraData>] = [],
        unreadCount: UnreadCount? = nil
    ) {
        self.devices = devices
        self.mutedUsers = mutedUsers
        self.unreadCount = unreadCount
        
        super.init(
            id: id,
            name: name,
            imageURL: imageURL,
            role: role,
            createdAt: createdAt,
            updatedAt: updatedAt,
            lastActiveAt: lastActiveAt,
            isOnline: isOnline,
            isInvisible: isInvisible,
            isBanned: isBanned,
            teams: teams,
            extraData: extraData
        )
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: UserPayloadsCodingKeys.self)
        devices = try container.decodeIfPresent([DevicePayload].self, forKey: .devices) ?? []
        mutedUsers = try container.decodeIfPresent([MutedUserPayload<ExtraData>].self, forKey: .mutedUsers) ?? []
        unreadCount = try? UnreadCount(from: decoder)
        
        try super.init(from: decoder)
    }
}

/// An object describing the outgoing user JSON payload.
struct CurrentUserUpdateRequestBody<ExtraData: UserExtraData>: Encodable {
    let id: String
    let set: UserData<ExtraData>
    let unset: [UserDataKey]
    
    init(
        id: String,
        set: UserData<ExtraData> = .init(),
        unset: [UserDataKey] = []
    ) {
        self.id = id
        self.set = set
        self.unset = unset
    }
    
    enum UserDataKey: RawRepresentable, Encodable, Equatable {
        case name
        case image
        case extraDataKey(String)
        
        init(rawValue: String) {
            switch rawValue {
            case "name": self = .name
            case "image": self = .image
            default: self = .extraDataKey(rawValue)
            }
        }
        
        var rawValue: String {
            switch self {
            case .name: return "name"
            case .image: return "image"
            case let .extraDataKey(key): return key
            }
        }
    }
    
    struct UserData<ExtraData: UserExtraData>: Encodable {
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
}

struct CurrentUserUpdateResponse<ExtraData: UserExtraData>: Decodable {
    let user: UserPayload<ExtraData>
    let duration: String
    
    enum CodingKeys: String, CodingKey {
        case users
        case duration
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let users = try container.decode([String: UserPayload<ExtraData>].self, forKey: .users)
        if let user = users.first?.value {
            self.user = user
        } else {
            throw DecodingError.dataCorrupted(.init(codingPath: [CodingKeys.users], debugDescription: "Missing updated user."))
        }
        duration = try container.decode(String.self, forKey: .duration)
    }
}

/// An object describing the incoming muted-user JSON payload.
struct MutedUserPayload<ExtraData: UserExtraData>: Decodable {
    private enum CodingKeys: String, CodingKey {
        case mutedUser = "target"
        case created = "created_at"
        case updated = "updated_at"
    }
    
    let mutedUser: UserPayload<ExtraData>
    let created: Date
    let updated: Date
}

extension MutedUserPayload: Equatable {
    static func == (lhs: MutedUserPayload<ExtraData>, rhs: MutedUserPayload<ExtraData>) -> Bool {
        lhs.mutedUser.id == rhs.mutedUser.id && lhs.created == rhs.created
    }
}

/// A muted users response.
struct MutedUsersResponse<ExtraData: UserExtraData>: Decodable {
    private enum CodingKeys: String, CodingKey {
        case mutedUser = "mute"
        case currentUser = "own_user"
    }
    
    /// A muted user.
    public let mutedUser: MutedUserPayload<ExtraData>
    /// The current user.
    public let currentUser: CurrentUserPayload<ExtraData>
}

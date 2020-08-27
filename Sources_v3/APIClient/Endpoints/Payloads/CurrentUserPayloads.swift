//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

/// An object describing the incoming current user JSON payload.
class CurrentUserPayload<ExtraData: UserExtraData>: UserPayload<ExtraData> {
    /// A list of devices.
    let devices: [Device]
    /// Muted users.
    let mutedUsers: [MutedUser<ExtraData>]
    /// Unread channel and message counts
    let unreadCount: UnreadCount?
    
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
        extraData: ExtraData,
        devices: [Device] = [],
        mutedUsers: [MutedUser<ExtraData>] = [],
        unreadCount: UnreadCount? = nil
    ) {
        self.devices = devices
        self.mutedUsers = mutedUsers
        self.unreadCount = unreadCount
        
        super.init(
            id: id,
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
        devices = try container.decodeIfPresent([Device].self, forKey: .devices) ?? []
        mutedUsers = try container.decodeIfPresent([MutedUser<ExtraData>].self, forKey: .mutedUsers) ?? []
        unreadCount = try? UnreadCount(from: decoder)
        
        try super.init(from: decoder)
    }
}

/// An object describing the outgoing user JSON payload.
class CurrentUserRequestBody<ExtraData: UserExtraData>: Encodable {
    // TODO: Add more fields while working on CIS-235
}

/// A muted user.
struct MutedUser<ExtraData: UserExtraData>: Decodable {
    private enum CodingKeys: String, CodingKey {
        case mutedUser = "target"
        case created = "created_at"
        case updated = "updated_at"
    }
    
    let mutedUser: UserPayload<ExtraData>
    let created: Date
    let updated: Date
}

extension MutedUser: Equatable {
    static func == (lhs: MutedUser<ExtraData>, rhs: MutedUser<ExtraData>) -> Bool {
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
    public let mutedUser: MutedUser<ExtraData>
    /// The current user.
    public let currentUser: CurrentUserPayload<ExtraData>
}

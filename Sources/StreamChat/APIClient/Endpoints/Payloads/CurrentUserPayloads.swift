//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// An object describing the incoming current user JSON payload.
class CurrentUserPayload<ExtraData: ExtraDataTypes>: UserPayload<ExtraData.User> {
    /// A list of devices.
    let devices: [DevicePayload]
    /// Muted users.
    let mutedUsers: [MutedUserPayload<ExtraData.User>]
    /// Muted channels.
    let mutedChannels: [MutedChannelPayload<ExtraData>]
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
        teams: [TeamId] = [],
        extraData: ExtraData.User,
        extraPayload: [String: RawJSON],
        devices: [DevicePayload] = [],
        mutedUsers: [MutedUserPayload<ExtraData.User>] = [],
        mutedChannels: [MutedChannelPayload<ExtraData>] = [],
        unreadCount: UnreadCount? = nil
    ) {
        self.devices = devices
        self.mutedUsers = mutedUsers
        self.mutedChannels = mutedChannels
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
            extraData: extraData,
            extraPayload: extraPayload
        )
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: UserPayloadsCodingKeys.self)
        devices = try container.decodeIfPresent([DevicePayload].self, forKey: .devices) ?? []
        mutedUsers = try container.decodeIfPresent([MutedUserPayload<ExtraData.User>].self, forKey: .mutedUsers) ?? []
        mutedChannels = try container.decodeIfPresent([MutedChannelPayload<ExtraData>].self, forKey: .mutedChannels) ?? []
        unreadCount = try? UnreadCount(from: decoder)
        
        try super.init(from: decoder)
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
struct MutedUsersResponse<ExtraData: ExtraDataTypes>: Decodable {
    private enum CodingKeys: String, CodingKey {
        case mutedUser = "mute"
        case currentUser = "own_user"
    }
    
    /// A muted user.
    public let mutedUser: MutedUserPayload<ExtraData.User>
    /// The current user.
    public let currentUser: CurrentUserPayload<ExtraData>
}

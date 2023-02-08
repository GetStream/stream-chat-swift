//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

/// An object describing the incoming current user JSON payload.
class CurrentUserPayload: UserPayload {
    /// A list of devices.
    let devices: [DevicePayload]
    /// Muted users.
    let mutedUsers: [MutedUserPayload]
    /// Muted channels.
    let mutedChannels: [MutedChannelPayload]
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
        extraData: [String: RawJSON],
        devices: [DevicePayload] = [],
        mutedUsers: [MutedUserPayload] = [],
        mutedChannels: [MutedChannelPayload] = [],
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
            extraData: extraData
        )
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: UserPayloadsCodingKeys.self)
        devices = try container.decodeIfPresent([DevicePayload].self, forKey: .devices) ?? []
        mutedUsers = try container.decodeIfPresent([MutedUserPayload].self, forKey: .mutedUsers) ?? []
        mutedChannels = try container.decodeIfPresent([MutedChannelPayload].self, forKey: .mutedChannels) ?? []
        unreadCount = try? UnreadCount(from: decoder)

        try super.init(from: decoder)
    }

    override func hash(
        into hasher: inout Hasher
    ) {
        hasher.combine(devices)
        hasher.combine(mutedUsers)
        hasher.combine(mutedChannels)
        unreadCount.map { hasher.combine($0) }
        super.hash(into: &hasher)
    }

    static func == (
        lhs: CurrentUserPayload,
        rhs: CurrentUserPayload
    ) -> Bool {
        lhs.devices == rhs.devices
            && lhs.mutedUsers == rhs.mutedUsers
            && lhs.mutedChannels == rhs.mutedChannels
            && lhs.unreadCount == rhs.unreadCount
            && (lhs as UserPayload) == (rhs as UserPayload)
    }
}

/// An object describing the incoming muted-user JSON payload.
struct MutedUserPayload: Decodable, Hashable {
    private enum CodingKeys: String, CodingKey {
        case mutedUser = "target"
        case created = "created_at"
        case updated = "updated_at"
    }

    let mutedUser: UserPayload
    let created: Date
    let updated: Date
}

extension MutedUserPayload {
    static func == (lhs: MutedUserPayload, rhs: MutedUserPayload) -> Bool {
        lhs.mutedUser.id == rhs.mutedUser.id && lhs.created == rhs.created
    }
}

/// A muted users response.
struct MutedUsersResponse: Decodable {
    private enum CodingKeys: String, CodingKey {
        case mutedUser = "mute"
        case currentUser = "own_user"
    }

    /// A muted user.
    public let mutedUser: MutedUserPayload
    /// The current user.
    public let currentUser: CurrentUserPayload
}

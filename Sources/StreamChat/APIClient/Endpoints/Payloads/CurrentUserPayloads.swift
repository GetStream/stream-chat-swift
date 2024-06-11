//
// Copyright © 2024 Stream.io Inc. All rights reserved.
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
    /// Blocked users.
    let blockedUsers: [BlockingUserPayload]
    /// Unread channel and message counts
    let unreadCount: UnreadCount?
    /// The current privacy settings of the user.
    let privacySettings: UserPrivacySettingsPayload?

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
        extraData: [String: RawJSON],
        devices: [DevicePayload] = [],
        mutedUsers: [MutedUserPayload] = [],
        mutedChannels: [MutedChannelPayload] = [],
        blockedUsers: [BlockingUserPayload] = [],
        unreadCount: UnreadCount? = nil,
        privacySettings: UserPrivacySettingsPayload? = nil
    ) {
        self.devices = devices
        self.mutedUsers = mutedUsers
        self.mutedChannels = mutedChannels
        self.blockedUsers = blockedUsers
        self.unreadCount = unreadCount
        self.privacySettings = privacySettings

        super.init(
            id: id,
            name: name,
            imageURL: imageURL,
            role: role,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deactivatedAt: deactivatedAt,
            lastActiveAt: lastActiveAt,
            isOnline: isOnline,
            isInvisible: isInvisible,
            isBanned: isBanned,
            teams: teams,
            language: language,
            extraData: extraData
        )
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: UserPayloadsCodingKeys.self)
        devices = try container.decodeIfPresent([DevicePayload].self, forKey: .devices) ?? []
        mutedUsers = try container.decodeIfPresent([MutedUserPayload].self, forKey: .mutedUsers) ?? []
        mutedChannels = try container.decodeIfPresent([MutedChannelPayload].self, forKey: .mutedChannels) ?? []
        blockedUsers = try container.decodeIfPresent([BlockingUserPayload].self, forKey: .blockedUsers) ?? []
        unreadCount = try? UnreadCount(from: decoder)
        privacySettings = try container.decodeIfPresent(UserPrivacySettingsPayload.self, forKey: .privacySettings)

        try super.init(from: decoder)
    }
}

/// An object describing the incoming muted-user JSON payload.
struct MutedUserPayload: Decodable {
    private enum CodingKeys: String, CodingKey {
        case mutedUser = "target"
        case created = "created_at"
        case updated = "updated_at"
    }

    let mutedUser: UserPayload
    let created: Date
    let updated: Date
}

extension MutedUserPayload: Equatable {
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

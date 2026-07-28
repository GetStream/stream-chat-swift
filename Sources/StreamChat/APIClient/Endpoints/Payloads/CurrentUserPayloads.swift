//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// An object describing the incoming current user JSON payload.
final class CurrentUserPayload: UserPayload {
    /// A list of devices.
    let devices: [Device]
    /// Muted users.
    let mutedUsers: [MutedUserPayload]
    /// Muted channels.
    let mutedChannels: [MutedChannelPayload]
    /// Unread channel and message counts
    let unreadCount: UnreadCountPayload?
    /// The current privacy settings of the user.
    let privacySettings: UserPrivacySettingsPayload?
    /// Whether the user is invisible to others. Only the own user carries it.
    let isInvisible: Bool
    /// Push preference for the user.
    let pushPreference: PushPreference?

    init(
        id: String,
        name: String?,
        imageURL: URL?,
        role: UserRole,
        teamsRole: [String: UserRole]?,
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
        devices: [Device] = [],
        mutedUsers: [MutedUserPayload] = [],
        mutedChannels: [MutedChannelPayload] = [],
        unreadCount: UnreadCountPayload? = nil,
        privacySettings: UserPrivacySettingsPayload? = nil,
        blockedUserIds: Set<UserId> = [],
        pushPreference: PushPreference?
    ) {
        self.devices = devices
        self.mutedUsers = mutedUsers
        self.mutedChannels = mutedChannels
        self.unreadCount = unreadCount
        self.privacySettings = privacySettings
        self.isInvisible = isInvisible
        self.pushPreference = pushPreference

        super.init(
            banned: isBanned,
            blockedUserIds: Array(blockedUserIds),
            createdAt: createdAt,
            custom: extraData,
            deactivatedAt: deactivatedAt,
            id: id,
            image: imageURL?.absoluteString,
            language: language.map(TranslationLanguage.init(languageCode:)),
            lastActive: lastActiveAt,
            name: name,
            online: isOnline,
            role: role,
            teams: teams,
            teamsRole: teamsRole,
            updatedAt: updatedAt
        )
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: UserPayloadsCodingKeys.self)
        devices = try container.decodeIfPresent([Device].self, forKey: .devices) ?? []
        mutedUsers = try container.decodeIfPresent([MutedUserPayload].self, forKey: .mutedUsers) ?? []
        mutedChannels = try container.decodeIfPresent([MutedChannelPayload].self, forKey: .mutedChannels) ?? []
        unreadCount = try? UnreadCountPayload(from: decoder)
        privacySettings = try container.decodeIfPresent(UserPrivacySettingsPayload.self, forKey: .privacySettings)
        isInvisible = try container.decodeIfPresent(Bool.self, forKey: .isInvisible) ?? false
        pushPreference = try container.decodeIfPresent(PushPreference.self, forKey: .pushPreference)

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

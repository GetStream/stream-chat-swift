//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class OwnUserResponse: Sendable, Decodable {
    let user: UserPayload
    let channelMutes: [MutedChannelPayload]
    let devices: [Device]
    let invisible: Bool
    let mutes: [MutedUserPayload]
    /// The privacy settings of the user.
    let privacySettings: UserPrivacySettings?
    /// The push preference details.
    let pushPreferences: PushPreference?
    let totalUnreadCount: Int
    let totalUnreadCountByTeam: [String: Int]?
    let unreadChannels: Int
    let unreadThreads: Int

    init(
        user: UserPayload,
        channelMutes: [MutedChannelPayload],
        devices: [Device],
        invisible: Bool,
        mutes: [MutedUserPayload],
        privacySettings: UserPrivacySettings? = nil,
        pushPreferences: PushPreference? = nil,
        totalUnreadCount: Int,
        totalUnreadCountByTeam: [String: Int]? = nil,
        unreadChannels: Int,
        unreadThreads: Int
    ) {
        self.user = user
        self.channelMutes = channelMutes
        self.devices = devices
        self.invisible = invisible
        self.mutes = mutes
        self.privacySettings = privacySettings
        self.pushPreferences = pushPreferences
        self.totalUnreadCount = totalUnreadCount
        self.totalUnreadCountByTeam = totalUnreadCountByTeam
        self.unreadChannels = unreadChannels
        self.unreadThreads = unreadThreads
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        user = try UserPayload(from: decoder)
        channelMutes = try container.decodeArrayIgnoringFailures(
            [MutedChannelPayload].self,
            forKey: .channelMutes
        )
        devices = try container.decodeArrayIgnoringFailures([Device].self, forKey: .devices)
        invisible = try container.decodeIfPresent(Bool.self, forKey: .invisible) ?? false
        mutes = try container.decode([MutedUserPayload].self, forKey: .mutes)
        privacySettings = try container.decodeIfPresent(
            UserPrivacySettings.self,
            forKey: .privacySettings
        )
        pushPreferences = try container.decodeIfPresent(
            PushPreference.self,
            forKey: .pushPreferences
        )
        totalUnreadCount = try container.decode(Int.self, forKey: .totalUnreadCount)
        totalUnreadCountByTeam = try container.decodeIfPresent(
            [String: Int].self,
            forKey: .totalUnreadCountByTeam
        )
        unreadChannels = try container.decode(Int.self, forKey: .unreadChannels)
        unreadThreads = try container.decodeIfPresent(Int.self, forKey: .unreadThreads) ?? 0
    }
}

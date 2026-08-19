//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public struct PushPreferenceLevel: RawRepresentable, Codable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let `default` = Self(rawValue: "default")
    public static let all = Self(rawValue: "all")
    public static let allMentions = Self(rawValue: "all_mentions")
    public static let directMentions = Self(rawValue: "direct_mentions")
    public static let mentions = Self(rawValue: "mentions")
    public static let none = Self(rawValue: "none")
}

final class PushPreferenceInput: Sendable, Codable, JSONEncodable {
    /// Set the push preferences for a specific channel. If empty it sets the default for the user
    let channelCid: String?
    /// Set the level of chat push notifications for the user. Note: "mentions" is deprecated in favor of "direct_mentions". One of: all, mentions, direct_mentions, all_mentions, none, default
    let chatLevel: PushPreferenceLevel?
    /// Disable push notifications till a certain time
    let disabledUntil: Date?
    /// Remove the disabled until time. (IE stop snoozing notifications)
    let removeDisable: Bool?
    /// The user id for which to set the push preferences. Required when using server side auths, defaults to current user with client side auth.
    let userId: String?

    init(
        channelCid: String? = nil,
        chatLevel: PushPreferenceLevel? = nil,
        disabledUntil: Date? = nil,
        removeDisable: Bool? = nil,
        userId: String? = nil
    ) {
        self.channelCid = channelCid
        self.chatLevel = chatLevel
        self.disabledUntil = disabledUntil
        self.removeDisable = removeDisable
        self.userId = userId
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channelCid = "channel_cid"
        case chatLevel = "chat_level"
        case disabledUntil = "disabled_until"
        case removeDisable = "remove_disable"
        case userId = "user_id"
    }
}

extension PushPreferenceInput: Hashable {
    static func == (
        lhs: PushPreferenceInput,
        rhs: PushPreferenceInput
    ) -> Bool {
        lhs.channelCid == rhs.channelCid &&
            lhs.chatLevel == rhs.chatLevel &&
            lhs.disabledUntil == rhs.disabledUntil &&
            lhs.removeDisable == rhs.removeDisable &&
            lhs.userId == rhs.userId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(channelCid)
        hasher.combine(chatLevel)
        hasher.combine(disabledUntil)
        hasher.combine(removeDisable)
        hasher.combine(userId)
    }
}

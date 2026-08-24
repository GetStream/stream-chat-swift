//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class PushPreferenceInput: Sendable, Encodable, JSONEncodable {
    enum PushPreferenceInputChatLevel: String, Sendable, Encodable, CaseIterable {
        case `default`
        case all
        case allMentions = "all_mentions"
        case directMentions = "direct_mentions"
        case mentions
        case none
        case unknown = "_unknown"

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let decodedValue = try? container.decode(String.self),
               let value = Self(rawValue: decodedValue) {
                self = value
            } else {
                self = .unknown
            }
        }
    }
    
    /// Set the push preferences for a specific channel. If empty it sets the default for the user
    let channelCid: String?
    /// Set the level of chat push notifications for the user. Note: "mentions" is deprecated in favor of "direct_mentions". One of: all, mentions, direct_mentions, all_mentions, none, default
    let chatLevel: PushPreferenceInputChatLevel?
    /// Disable push notifications till a certain time
    let disabledUntil: Date?
    /// Remove the disabled until time. (IE stop snoozing notifications)
    let removeDisable: Bool?
    /// The user id for which to set the push preferences. Required when using server side auths, defaults to current user with client side auth.
    let userId: String?

    init(
        channelCid: String? = nil,
        chatLevel: PushPreferenceInputChatLevel? = nil,
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

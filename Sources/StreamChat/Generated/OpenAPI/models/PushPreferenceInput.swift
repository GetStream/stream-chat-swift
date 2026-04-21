//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class PushPreferenceInput: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    enum PushPreferenceInputCallLevel: String, Sendable, Codable, CaseIterable {
        case all
        case `default`
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
    
    enum PushPreferenceInputChatLevel: String, Sendable, Codable, CaseIterable {
        case all
        case allMentions = "all_mentions"
        case `default`
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
    
    enum PushPreferenceInputFeedsLevel: String, Sendable, Codable, CaseIterable {
        case all
        case `default`
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

    /// Set the level of call push notifications for the user. One of: all, none, default
    var callLevel: PushPreferenceInputCallLevel?
    /// Set the push preferences for a specific channel. If empty it sets the default for the user
    var channelCid: String?
    /// Set the level of chat push notifications for the user. Note: "mentions" is deprecated in favor of "direct_mentions". One of: all, mentions, direct_mentions, all_mentions, none, default
    var chatLevel: PushPreferenceInputChatLevel?
    var chatPreferences: ChatPreferencesInput?
    /// Disable push notifications till a certain time
    var disabledUntil: Date?
    /// Set the level of feeds push notifications for the user. One of: all, none, default
    var feedsLevel: PushPreferenceInputFeedsLevel?
    var feedsPreferences: FeedsPreferences?
    /// Remove the disabled until time. (IE stop snoozing notifications)
    var removeDisable: Bool?
    /// The user id for which to set the push preferences. Required when using server side auths, defaults to current user with client side auth.
    var userId: String?

    init(callLevel: PushPreferenceInputCallLevel? = nil, channelCid: String? = nil, chatLevel: PushPreferenceInputChatLevel? = nil, chatPreferences: ChatPreferencesInput? = nil, disabledUntil: Date? = nil, feedsLevel: PushPreferenceInputFeedsLevel? = nil, feedsPreferences: FeedsPreferences? = nil, removeDisable: Bool? = nil, userId: String? = nil) {
        self.callLevel = callLevel
        self.channelCid = channelCid
        self.chatLevel = chatLevel
        self.chatPreferences = chatPreferences
        self.disabledUntil = disabledUntil
        self.feedsLevel = feedsLevel
        self.feedsPreferences = feedsPreferences
        self.removeDisable = removeDisable
        self.userId = userId
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case callLevel = "call_level"
        case channelCid = "channel_cid"
        case chatLevel = "chat_level"
        case chatPreferences = "chat_preferences"
        case disabledUntil = "disabled_until"
        case feedsLevel = "feeds_level"
        case feedsPreferences = "feeds_preferences"
        case removeDisable = "remove_disable"
        case userId = "user_id"
    }

    static func == (lhs: PushPreferenceInput, rhs: PushPreferenceInput) -> Bool {
        lhs.callLevel == rhs.callLevel &&
            lhs.channelCid == rhs.channelCid &&
            lhs.chatLevel == rhs.chatLevel &&
            lhs.chatPreferences == rhs.chatPreferences &&
            lhs.disabledUntil == rhs.disabledUntil &&
            lhs.feedsLevel == rhs.feedsLevel &&
            lhs.feedsPreferences == rhs.feedsPreferences &&
            lhs.removeDisable == rhs.removeDisable &&
            lhs.userId == rhs.userId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(callLevel)
        hasher.combine(channelCid)
        hasher.combine(chatLevel)
        hasher.combine(chatPreferences)
        hasher.combine(disabledUntil)
        hasher.combine(feedsLevel)
        hasher.combine(feedsPreferences)
        hasher.combine(removeDisable)
        hasher.combine(userId)
    }
}

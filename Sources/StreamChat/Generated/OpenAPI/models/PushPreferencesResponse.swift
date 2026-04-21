//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class PushPreferencesResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var callLevel: String?
    var chatLevel: String?
    var chatPreferences: ChatPreferencesResponse?
    var disabledUntil: Date?
    var feedsLevel: String?
    var feedsPreferences: FeedsPreferencesResponse?

    init(callLevel: String? = nil, chatLevel: String? = nil, chatPreferences: ChatPreferencesResponse? = nil, disabledUntil: Date? = nil, feedsLevel: String? = nil, feedsPreferences: FeedsPreferencesResponse? = nil) {
        self.callLevel = callLevel
        self.chatLevel = chatLevel
        self.chatPreferences = chatPreferences
        self.disabledUntil = disabledUntil
        self.feedsLevel = feedsLevel
        self.feedsPreferences = feedsPreferences
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case callLevel = "call_level"
        case chatLevel = "chat_level"
        case chatPreferences = "chat_preferences"
        case disabledUntil = "disabled_until"
        case feedsLevel = "feeds_level"
        case feedsPreferences = "feeds_preferences"
    }

    static func == (lhs: PushPreferencesResponse, rhs: PushPreferencesResponse) -> Bool {
        lhs.callLevel == rhs.callLevel &&
            lhs.chatLevel == rhs.chatLevel &&
            lhs.chatPreferences == rhs.chatPreferences &&
            lhs.disabledUntil == rhs.disabledUntil &&
            lhs.feedsLevel == rhs.feedsLevel &&
            lhs.feedsPreferences == rhs.feedsPreferences
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(callLevel)
        hasher.combine(chatLevel)
        hasher.combine(chatPreferences)
        hasher.combine(disabledUntil)
        hasher.combine(feedsLevel)
        hasher.combine(feedsPreferences)
    }
}

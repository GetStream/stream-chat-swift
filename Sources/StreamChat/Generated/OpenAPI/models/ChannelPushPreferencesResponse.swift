//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ChannelPushPreferencesResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var chatLevel: String?
    var chatPreferences: ChatPreferencesResponse?
    var disabledUntil: Date?

    init(chatLevel: String? = nil, chatPreferences: ChatPreferencesResponse? = nil, disabledUntil: Date? = nil) {
        self.chatLevel = chatLevel
        self.chatPreferences = chatPreferences
        self.disabledUntil = disabledUntil
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case chatLevel = "chat_level"
        case chatPreferences = "chat_preferences"
        case disabledUntil = "disabled_until"
    }

    static func == (lhs: ChannelPushPreferencesResponse, rhs: ChannelPushPreferencesResponse) -> Bool {
        lhs.chatLevel == rhs.chatLevel &&
            lhs.chatPreferences == rhs.chatPreferences &&
            lhs.disabledUntil == rhs.disabledUntil
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(chatLevel)
        hasher.combine(chatPreferences)
        hasher.combine(disabledUntil)
    }
}

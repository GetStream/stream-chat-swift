//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UpsertPushPreferencesResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Duration of the request in milliseconds
    var duration: String
    /// The channel specific push notification preferences, only returned for channels you've edited.
    var userChannelPreferences: [String: [String: ChannelPushPreferencesResponse?]]
    /// The user preferences, always returned regardless if you edited it
    var userPreferences: [String: PushPreferencesResponse?]

    init(duration: String, userChannelPreferences: [String: [String: ChannelPushPreferencesResponse?]], userPreferences: [String: PushPreferencesResponse?]) {
        self.duration = duration
        self.userChannelPreferences = userChannelPreferences
        self.userPreferences = userPreferences
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case userChannelPreferences = "user_channel_preferences"
        case userPreferences = "user_preferences"
    }

    static func == (lhs: UpsertPushPreferencesResponse, rhs: UpsertPushPreferencesResponse) -> Bool {
        lhs.duration == rhs.duration &&
            lhs.userChannelPreferences == rhs.userChannelPreferences &&
            lhs.userPreferences == rhs.userPreferences
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(duration)
        hasher.combine(userChannelPreferences)
        hasher.combine(userPreferences)
    }
}

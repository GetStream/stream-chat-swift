//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

final class UpsertPushPreferencesResponse: Sendable, Codable, JSONEncodable {
    /// The channel specific push notification preferences, only returned for channels you've edited.
    let userChannelPreferences: [String: [String: PushPreferencesResponse]]
    /// The user preferences, always returned regardless if you edited it
    let userPreferences: [String: PushPreferencesResponse]

    init(
        userChannelPreferences: [String: [String: PushPreferencesResponse]],
        userPreferences: [String: PushPreferencesResponse]
    ) {
        self.userChannelPreferences = userChannelPreferences
        self.userPreferences = userPreferences
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case userChannelPreferences = "user_channel_preferences"
        case userPreferences = "user_preferences"
    }
}

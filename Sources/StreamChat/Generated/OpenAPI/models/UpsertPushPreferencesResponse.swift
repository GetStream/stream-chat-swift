//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

final class UpsertPushPreferencesResponse: Sendable, Decodable {
    /// The channel specific push notification preferences, only returned for channels you've edited.
    let userChannelPreferences: [String: [String: PushPreference]]
    /// The user preferences, always returned regardless if you edited it
    let userPreferences: [String: PushPreference]

    init(
        userChannelPreferences: [String: [String: PushPreference]],
        userPreferences: [String: PushPreference]
    ) {
        self.userChannelPreferences = userChannelPreferences
        self.userPreferences = userPreferences
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case userChannelPreferences = "user_channel_preferences"
        case userPreferences = "user_preferences"
    }
}

//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.userChannelPreferences = try container.decode(
            [String: [String: PushPreference]].self,
            forKey: .userChannelPreferences
        )
        self.userPreferences = try container.decode(
            [String: PushPreference].self,
            forKey: .userPreferences
        )
    }
}

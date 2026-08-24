//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UpsertPushPreferencesRequest: Sendable, Encodable, JSONEncodable {
    /// A list of push preferences for channels, calls, or the user.
    let preferences: [PushPreferenceInput]

    init(preferences: [PushPreferenceInput]) {
        self.preferences = preferences
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case preferences
    }
}

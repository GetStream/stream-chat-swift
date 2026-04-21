//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UpsertPushPreferencesRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// A list of push preferences for channels, calls, or the user.
    var preferences: [PushPreferenceInput]

    init(preferences: [PushPreferenceInput]) {
        self.preferences = preferences
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case preferences
    }

    static func == (lhs: UpsertPushPreferencesRequest, rhs: UpsertPushPreferencesRequest) -> Bool {
        lhs.preferences == rhs.preferences
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(preferences)
    }
}

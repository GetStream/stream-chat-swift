//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UpdateBlockListRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var isLeetCheckEnabled: Bool?
    var isPluralCheckEnabled: Bool?
    var team: String?
    /// List of words to block
    var words: [String]?

    init(isLeetCheckEnabled: Bool? = nil, isPluralCheckEnabled: Bool? = nil, team: String? = nil, words: [String]? = nil) {
        self.isLeetCheckEnabled = isLeetCheckEnabled
        self.isPluralCheckEnabled = isPluralCheckEnabled
        self.team = team
        self.words = words
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case isLeetCheckEnabled = "is_leet_check_enabled"
        case isPluralCheckEnabled = "is_plural_check_enabled"
        case team
        case words
    }

    static func == (lhs: UpdateBlockListRequest, rhs: UpdateBlockListRequest) -> Bool {
        lhs.isLeetCheckEnabled == rhs.isLeetCheckEnabled &&
            lhs.isPluralCheckEnabled == rhs.isPluralCheckEnabled &&
            lhs.team == rhs.team &&
            lhs.words == rhs.words
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(isLeetCheckEnabled)
        hasher.combine(isPluralCheckEnabled)
        hasher.combine(team)
        hasher.combine(words)
    }
}

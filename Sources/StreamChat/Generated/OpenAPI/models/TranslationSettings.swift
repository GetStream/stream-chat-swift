//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class TranslationSettings: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var enabled: Bool
    var languages: [String]

    init(enabled: Bool, languages: [String]) {
        self.enabled = enabled
        self.languages = languages
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case enabled
        case languages
    }

    static func == (lhs: TranslationSettings, rhs: TranslationSettings) -> Bool {
        lhs.enabled == rhs.enabled &&
            lhs.languages == rhs.languages
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(enabled)
        hasher.combine(languages)
    }
}

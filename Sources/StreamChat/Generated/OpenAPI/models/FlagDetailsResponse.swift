//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class FlagDetailsResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var automod: AutomodDetailsResponse?
    var extra: [String: RawJSON]?
    var originalText: String

    init(automod: AutomodDetailsResponse? = nil, extra: [String: RawJSON]? = nil, originalText: String) {
        self.automod = automod
        self.extra = extra
        self.originalText = originalText
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case automod
        case extra
        case originalText = "original_text"
    }

    static func == (lhs: FlagDetailsResponse, rhs: FlagDetailsResponse) -> Bool {
        lhs.automod == rhs.automod &&
            lhs.extra == rhs.extra &&
            lhs.originalText == rhs.originalText
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(automod)
        hasher.combine(extra)
        hasher.combine(originalText)
    }
}

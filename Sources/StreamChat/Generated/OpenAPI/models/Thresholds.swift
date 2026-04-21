//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class Thresholds: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var explicit: LabelThresholds?
    var spam: LabelThresholds?
    var toxic: LabelThresholds?

    init(explicit: LabelThresholds? = nil, spam: LabelThresholds? = nil, toxic: LabelThresholds? = nil) {
        self.explicit = explicit
        self.spam = spam
        self.toxic = toxic
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case explicit
        case spam
        case toxic
    }

    static func == (lhs: Thresholds, rhs: Thresholds) -> Bool {
        lhs.explicit == rhs.explicit &&
            lhs.spam == rhs.spam &&
            lhs.toxic == rhs.toxic
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(explicit)
        hasher.combine(spam)
        hasher.combine(toxic)
    }
}

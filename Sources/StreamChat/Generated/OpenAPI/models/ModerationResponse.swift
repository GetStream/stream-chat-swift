//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ModerationResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var action: String
    var explicit: Float
    var spam: Float
    var toxic: Float

    init(action: String, explicit: Float, spam: Float, toxic: Float) {
        self.action = action
        self.explicit = explicit
        self.spam = spam
        self.toxic = toxic
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case action
        case explicit
        case spam
        case toxic
    }

    static func == (lhs: ModerationResponse, rhs: ModerationResponse) -> Bool {
        lhs.action == rhs.action &&
            lhs.explicit == rhs.explicit &&
            lhs.spam == rhs.spam &&
            lhs.toxic == rhs.toxic
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(action)
        hasher.combine(explicit)
        hasher.combine(spam)
        hasher.combine(toxic)
    }
}

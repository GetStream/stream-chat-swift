//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class FlagResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var duration: String
    /// Unique identifier of the created moderation item
    var itemId: String

    init(duration: String, itemId: String) {
        self.duration = duration
        self.itemId = itemId
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case itemId = "item_id"
    }

    static func == (lhs: FlagResponse, rhs: FlagResponse) -> Bool {
        lhs.duration == rhs.duration &&
            lhs.itemId == rhs.itemId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(duration)
        hasher.combine(itemId)
    }
}

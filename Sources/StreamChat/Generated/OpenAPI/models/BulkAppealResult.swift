//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class BulkAppealResult: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var appealId: String
    var appealItem: AppealItemResponse?

    init(appealId: String, appealItem: AppealItemResponse? = nil) {
        self.appealId = appealId
        self.appealItem = appealItem
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case appealId = "appeal_id"
        case appealItem = "appeal_item"
    }

    static func == (lhs: BulkAppealResult, rhs: BulkAppealResult) -> Bool {
        lhs.appealId == rhs.appealId &&
            lhs.appealItem == rhs.appealItem
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(appealId)
        hasher.combine(appealItem)
    }
}

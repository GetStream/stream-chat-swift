//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class BulkAppealError: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var appealId: String
    var error: String

    init(appealId: String, error: String) {
        self.appealId = appealId
        self.error = error
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case appealId = "appeal_id"
        case error
    }

    static func == (lhs: BulkAppealError, rhs: BulkAppealError) -> Bool {
        lhs.appealId == rhs.appealId &&
            lhs.error == rhs.error
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(appealId)
        hasher.combine(error)
    }
}

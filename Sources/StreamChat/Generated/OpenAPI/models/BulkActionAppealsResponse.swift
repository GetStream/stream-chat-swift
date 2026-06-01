//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class BulkActionAppealsResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var duration: String
    /// Appeals that could not be processed, with per-item error messages
    var errors: [BulkAppealError]
    /// Successfully processed appeals
    var results: [BulkAppealResult]

    init(duration: String, errors: [BulkAppealError], results: [BulkAppealResult]) {
        self.duration = duration
        self.errors = errors
        self.results = results
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case errors
        case results
    }

    static func == (lhs: BulkActionAppealsResponse, rhs: BulkActionAppealsResponse) -> Bool {
        lhs.duration == rhs.duration &&
            lhs.errors == rhs.errors &&
            lhs.results == rhs.results
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(duration)
        hasher.combine(errors)
        hasher.combine(results)
    }
}

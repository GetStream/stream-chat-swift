//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class BulkDeleteActionConfigResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Number of action configs deleted
    var deleted: Int
    var duration: String

    init(deleted: Int, duration: String) {
        self.deleted = deleted
        self.duration = duration
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case deleted
        case duration
    }

    static func == (lhs: BulkDeleteActionConfigResponse, rhs: BulkDeleteActionConfigResponse) -> Bool {
        lhs.deleted == rhs.deleted &&
            lhs.duration == rhs.duration
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(deleted)
        hasher.combine(duration)
    }
}

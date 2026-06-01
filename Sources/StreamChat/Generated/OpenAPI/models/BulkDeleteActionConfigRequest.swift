//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class BulkDeleteActionConfigRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// UUIDs of the action configs to delete
    var ids: [String]

    init(ids: [String]) {
        self.ids = ids
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case ids
    }

    static func == (lhs: BulkDeleteActionConfigRequest, rhs: BulkDeleteActionConfigRequest) -> Bool {
        lhs.ids == rhs.ids
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(ids)
    }
}

//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class BulkUpsertActionConfigResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// The created or updated action configs in the same order as the request
    var actionConfigs: [ModerationActionConfigResponse]
    var duration: String

    init(actionConfigs: [ModerationActionConfigResponse], duration: String) {
        self.actionConfigs = actionConfigs
        self.duration = duration
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case actionConfigs = "action_configs"
        case duration
    }

    static func == (lhs: BulkUpsertActionConfigResponse, rhs: BulkUpsertActionConfigResponse) -> Bool {
        lhs.actionConfigs == rhs.actionConfigs &&
            lhs.duration == rhs.duration
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(actionConfigs)
        hasher.combine(duration)
    }
}

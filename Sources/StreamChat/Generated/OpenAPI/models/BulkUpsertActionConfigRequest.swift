//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class BulkUpsertActionConfigRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// List of action configs to create or update
    var actionConfigs: [UpsertActionConfigItem]

    init(actionConfigs: [UpsertActionConfigItem]) {
        self.actionConfigs = actionConfigs
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case actionConfigs = "action_configs"
    }

    static func == (lhs: BulkUpsertActionConfigRequest, rhs: BulkUpsertActionConfigRequest) -> Bool {
        lhs.actionConfigs == rhs.actionConfigs
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(actionConfigs)
    }
}

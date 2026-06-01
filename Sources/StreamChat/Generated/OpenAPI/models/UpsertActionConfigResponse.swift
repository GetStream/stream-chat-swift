//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UpsertActionConfigResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var actionConfig: ModerationActionConfigResponse?
    var duration: String

    init(actionConfig: ModerationActionConfigResponse? = nil, duration: String) {
        self.actionConfig = actionConfig
        self.duration = duration
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case actionConfig = "action_config"
        case duration
    }

    static func == (lhs: UpsertActionConfigResponse, rhs: UpsertActionConfigResponse) -> Bool {
        lhs.actionConfig == rhs.actionConfig &&
            lhs.duration == rhs.duration
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(actionConfig)
        hasher.combine(duration)
    }
}

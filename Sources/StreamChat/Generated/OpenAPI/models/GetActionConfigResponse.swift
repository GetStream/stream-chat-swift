//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class GetActionConfigResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Moderation action configs grouped by entity type, sorted by order ascending
    var actionConfig: [String: [ModerationActionConfigResponse]]
    var duration: String

    init(actionConfig: [String: [ModerationActionConfigResponse]], duration: String) {
        self.actionConfig = actionConfig
        self.duration = duration
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case actionConfig = "action_config"
        case duration
    }

    static func == (lhs: GetActionConfigResponse, rhs: GetActionConfigResponse) -> Bool {
        lhs.actionConfig == rhs.actionConfig &&
            lhs.duration == rhs.duration
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(actionConfig)
        hasher.combine(duration)
    }
}

//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class VelocityFilterConfig: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var advancedFilters: Bool
    var async: Bool?
    var cascadingActions: Bool
    var cidsPerUser: Int
    var enabled: Bool
    var firstMessageOnly: Bool
    var rules: [VelocityFilterConfigRule]

    init(advancedFilters: Bool, async: Bool? = nil, cascadingActions: Bool, cidsPerUser: Int, enabled: Bool, firstMessageOnly: Bool, rules: [VelocityFilterConfigRule]) {
        self.advancedFilters = advancedFilters
        self.async = async
        self.cascadingActions = cascadingActions
        self.cidsPerUser = cidsPerUser
        self.enabled = enabled
        self.firstMessageOnly = firstMessageOnly
        self.rules = rules
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case advancedFilters = "advanced_filters"
        case async
        case cascadingActions = "cascading_actions"
        case cidsPerUser = "cids_per_user"
        case enabled
        case firstMessageOnly = "first_message_only"
        case rules
    }

    static func == (lhs: VelocityFilterConfig, rhs: VelocityFilterConfig) -> Bool {
        lhs.advancedFilters == rhs.advancedFilters &&
            lhs.async == rhs.async &&
            lhs.cascadingActions == rhs.cascadingActions &&
            lhs.cidsPerUser == rhs.cidsPerUser &&
            lhs.enabled == rhs.enabled &&
            lhs.firstMessageOnly == rhs.firstMessageOnly &&
            lhs.rules == rhs.rules
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(advancedFilters)
        hasher.combine(async)
        hasher.combine(cascadingActions)
        hasher.combine(cidsPerUser)
        hasher.combine(enabled)
        hasher.combine(firstMessageOnly)
        hasher.combine(rules)
    }
}

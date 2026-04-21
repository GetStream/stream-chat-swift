//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class RuleBuilderConditionGroup: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var conditions: [RuleBuilderCondition]?
    var logic: String?

    init(conditions: [RuleBuilderCondition]? = nil, logic: String? = nil) {
        self.conditions = conditions
        self.logic = logic
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case conditions
        case logic
    }

    static func == (lhs: RuleBuilderConditionGroup, rhs: RuleBuilderConditionGroup) -> Bool {
        lhs.conditions == rhs.conditions &&
            lhs.logic == rhs.logic
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(conditions)
        hasher.combine(logic)
    }
}

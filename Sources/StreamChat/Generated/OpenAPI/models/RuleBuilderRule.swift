//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class RuleBuilderRule: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var action: RuleBuilderAction?
    var actionSequences: [CallRuleActionSequence]?
    var conditions: [RuleBuilderCondition]?
    var cooldownPeriod: String?
    var groups: [RuleBuilderConditionGroup]?
    var id: String?
    var logic: String?
    var ruleType: String

    init(action: RuleBuilderAction? = nil, actionSequences: [CallRuleActionSequence]? = nil, conditions: [RuleBuilderCondition]? = nil, cooldownPeriod: String? = nil, groups: [RuleBuilderConditionGroup]? = nil, id: String? = nil, logic: String? = nil, ruleType: String) {
        self.action = action
        self.actionSequences = actionSequences
        self.conditions = conditions
        self.cooldownPeriod = cooldownPeriod
        self.groups = groups
        self.id = id
        self.logic = logic
        self.ruleType = ruleType
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case action
        case actionSequences = "action_sequences"
        case conditions
        case cooldownPeriod = "cooldown_period"
        case groups
        case id
        case logic
        case ruleType = "rule_type"
    }

    static func == (lhs: RuleBuilderRule, rhs: RuleBuilderRule) -> Bool {
        lhs.action == rhs.action &&
            lhs.actionSequences == rhs.actionSequences &&
            lhs.conditions == rhs.conditions &&
            lhs.cooldownPeriod == rhs.cooldownPeriod &&
            lhs.groups == rhs.groups &&
            lhs.id == rhs.id &&
            lhs.logic == rhs.logic &&
            lhs.ruleType == rhs.ruleType
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(action)
        hasher.combine(actionSequences)
        hasher.combine(conditions)
        hasher.combine(cooldownPeriod)
        hasher.combine(groups)
        hasher.combine(id)
        hasher.combine(logic)
        hasher.combine(ruleType)
    }
}

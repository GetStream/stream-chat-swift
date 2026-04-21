//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class BodyguardSeverityRule: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    enum BodyguardSeverityRuleAction: String, Sendable, Codable, CaseIterable {
        case bounce
        case bounceFlag = "bounce_flag"
        case bounceRemove = "bounce_remove"
        case flag
        case remove
        case shadow
        case unknown = "_unknown"

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let decodedValue = try? container.decode(String.self),
               let value = Self(rawValue: decodedValue) {
                self = value
            } else {
                self = .unknown
            }
        }
    }
    
    enum BodyguardSeverityRuleSeverity: String, Sendable, Codable, CaseIterable {
        case critical
        case high
        case low
        case medium
        case unknown = "_unknown"

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let decodedValue = try? container.decode(String.self),
               let value = Self(rawValue: decodedValue) {
                self = value
            } else {
                self = .unknown
            }
        }
    }

    var action: BodyguardSeverityRuleAction
    var severity: BodyguardSeverityRuleSeverity

    init(action: BodyguardSeverityRuleAction, severity: BodyguardSeverityRuleSeverity) {
        self.action = action
        self.severity = severity
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case action
        case severity
    }

    static func == (lhs: BodyguardSeverityRule, rhs: BodyguardSeverityRule) -> Bool {
        lhs.action == rhs.action &&
            lhs.severity == rhs.severity
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(action)
        hasher.combine(severity)
    }
}

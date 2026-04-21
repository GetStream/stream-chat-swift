//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class BlockListRule: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    enum BlockListRuleAction: String, Sendable, Codable, CaseIterable {
        case bounce
        case bounceFlag = "bounce_flag"
        case bounceRemove = "bounce_remove"
        case flag
        case maskFlag = "mask_flag"
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

    var action: BlockListRuleAction
    var name: String
    var team: String

    init(action: BlockListRuleAction, name: String, team: String) {
        self.action = action
        self.name = name
        self.team = team
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case action
        case name
        case team
    }

    static func == (lhs: BlockListRule, rhs: BlockListRule) -> Bool {
        lhs.action == rhs.action &&
            lhs.name == rhs.name &&
            lhs.team == rhs.team
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(action)
        hasher.combine(name)
        hasher.combine(team)
    }
}

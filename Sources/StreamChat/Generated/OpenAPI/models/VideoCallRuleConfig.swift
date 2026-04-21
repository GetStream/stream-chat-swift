//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class VideoCallRuleConfig: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var flagAllLabels: Bool
    var flaggedLabels: [String]
    var rules: [HarmConfig]

    init(flagAllLabels: Bool, flaggedLabels: [String], rules: [HarmConfig]) {
        self.flagAllLabels = flagAllLabels
        self.flaggedLabels = flaggedLabels
        self.rules = rules
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case flagAllLabels = "flag_all_labels"
        case flaggedLabels = "flagged_labels"
        case rules
    }

    static func == (lhs: VideoCallRuleConfig, rhs: VideoCallRuleConfig) -> Bool {
        lhs.flagAllLabels == rhs.flagAllLabels &&
            lhs.flaggedLabels == rhs.flaggedLabels &&
            lhs.rules == rhs.rules
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(flagAllLabels)
        hasher.combine(flaggedLabels)
        hasher.combine(rules)
    }
}

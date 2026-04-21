//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ActionSequence: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var action: String
    var blur: Bool
    var cooldownPeriod: Int
    var threshold: Int
    var timeWindow: Int
    var warning: Bool
    var warningText: String

    init(action: String, blur: Bool, cooldownPeriod: Int, threshold: Int, timeWindow: Int, warning: Bool, warningText: String) {
        self.action = action
        self.blur = blur
        self.cooldownPeriod = cooldownPeriod
        self.threshold = threshold
        self.timeWindow = timeWindow
        self.warning = warning
        self.warningText = warningText
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case action
        case blur
        case cooldownPeriod = "cooldown_period"
        case threshold
        case timeWindow = "time_window"
        case warning
        case warningText = "warning_text"
    }

    static func == (lhs: ActionSequence, rhs: ActionSequence) -> Bool {
        lhs.action == rhs.action &&
            lhs.blur == rhs.blur &&
            lhs.cooldownPeriod == rhs.cooldownPeriod &&
            lhs.threshold == rhs.threshold &&
            lhs.timeWindow == rhs.timeWindow &&
            lhs.warning == rhs.warning &&
            lhs.warningText == rhs.warningText
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(action)
        hasher.combine(blur)
        hasher.combine(cooldownPeriod)
        hasher.combine(threshold)
        hasher.combine(timeWindow)
        hasher.combine(warning)
        hasher.combine(warningText)
    }
}

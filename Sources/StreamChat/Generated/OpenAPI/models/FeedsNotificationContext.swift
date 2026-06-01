//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class FeedsNotificationContext: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var target: FeedsNotificationTarget?
    var trigger: FeedsNotificationTrigger?

    init(target: FeedsNotificationTarget? = nil, trigger: FeedsNotificationTrigger? = nil) {
        self.target = target
        self.trigger = trigger
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case target
        case trigger
    }

    static func == (lhs: FeedsNotificationContext, rhs: FeedsNotificationContext) -> Bool {
        lhs.target == rhs.target &&
            lhs.trigger == rhs.trigger
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(target)
        hasher.combine(trigger)
    }
}

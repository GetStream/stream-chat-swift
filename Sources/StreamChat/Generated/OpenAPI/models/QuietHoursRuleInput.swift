//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// One recurring quiet window, expressed in local wall-clock time in the schedule's timezone.
final class QuietHoursRuleInput: Sendable, Encodable, JSONEncodable {
    /// The days of the week the window opens on, any of mon, tue, wed, thu, fri, sat, sun, each at most once. A window belongs to the day it opens: ["fri"] with 22:00 to 07:00 is quiet from Friday 22:00 until Saturday 07:00, and not on Saturday night. Empty or omitted means every day.
    let days: [QuietHoursDay]?
    /// When the window closes, as HH:MM local wall-clock time between 00:00 and 24:00. The end is exclusive: a window ending at 07:00 is already over at 07:00. An end earlier than start wraps past midnight into the next day (start 22:00, end 07:00). 24:00 means the end of the day, so start 00:00 with end 24:00 covers the whole day.
    let end: String
    /// When the window opens, as HH:MM local wall-clock time between 00:00 and 23:59. Must differ from end.
    let start: String

    init(days: [QuietHoursDay]? = nil, end: String, start: String) {
        self.days = days
        self.end = end
        self.start = start
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(days, forKey: .days)
        try container.encode(end, forKey: .end)
        try container.encode(start, forKey: .start)
    }
}

extension QuietHoursRuleInput: Hashable {
    static func == (lhs: QuietHoursRuleInput, rhs: QuietHoursRuleInput) -> Bool {
        lhs.days == rhs.days &&
            lhs.end == rhs.end &&
            lhs.start == rhs.start
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(days)
        hasher.combine(end)
        hasher.combine(start)
    }
}

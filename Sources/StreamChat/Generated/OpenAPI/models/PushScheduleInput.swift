//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A recurring quiet-hours schedule: while any quiet window is active, push notifications for the user are suppressed. Suppressed notifications are dropped, not delayed.
final class PushScheduleInput: Sendable, Encodable, JSONEncodable {
    /// The quiet windows, 1 to 7 rules. Push is suppressed while any rule is active. When present it replaces all stored rules; omit it to keep them, for example to change only the timezone. An empty array counts as omitted, so it cannot be used to clear the rules: use remove_schedule for that.
    let quietHours: [QuietHoursRuleInput]?
    /// IANA time zone name the quiet windows are evaluated in, for example Europe/Amsterdam or America/New_York. Daylight saving time is followed automatically for region-based names. Offsets such as +02:00 and the name "Local" are rejected; fixed-offset zones such as UTC or Etc/GMT-2 are accepted but never shift for daylight saving time. When updating an existing schedule, a non-empty timezone replaces the stored one and leaves the stored quiet_hours untouched.
    let timezone: String?

    init(quietHours: [QuietHoursRuleInput]? = nil, timezone: String? = nil) {
        self.quietHours = quietHours
        self.timezone = timezone
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(quietHours, forKey: .quietHours)
        try container.encodeIfPresent(timezone, forKey: .timezone)
    }
}

extension PushScheduleInput: Hashable {
    static func == (lhs: PushScheduleInput, rhs: PushScheduleInput) -> Bool {
        lhs.quietHours == rhs.quietHours &&
            lhs.timezone == rhs.timezone
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(quietHours)
        hasher.combine(timezone)
    }
}

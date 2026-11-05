//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public extension PushSchedule {
    /// Creates a quiet hours schedule.
    ///
    /// While any of the quiet windows is active, the server drops the user's chat push notifications.
    ///
    /// - Parameters:
    ///   - timezone: The time zone the quiet windows are evaluated in. Defaults to the device's time zone.
    ///   It must be a named time zone, such as `Europe/Amsterdam`: the server rejects fixed-offset
    ///   time zones created with `TimeZone(secondsFromGMT:)`.
    ///   - quietHours: The quiet windows, 1 to 7 rules.
    convenience init(timezone: TimeZone = .current, quietHours: [QuietHoursRule]) {
        self.init(quietHours: quietHours, timezone: timezone.identifier)
    }
}

public extension QuietHoursRule {
    /// Creates a recurring quiet window in the schedule's local wall-clock time.
    ///
    /// A window belongs to the day it opens on: `[.friday]` from `"22:00"` to `"07:00"`
    /// is quiet from Friday 22:00 until Saturday 07:00.
    ///
    /// - Parameters:
    ///   - days: The days the window opens on. `nil` or empty means every day.
    ///   - start: When the window opens, as `HH:mm` between `00:00` and `23:59`.
    ///   - end: When the window closes (exclusive), as `HH:mm` between `00:00` and `24:00`.
    ///   An end earlier than the start wraps past midnight. `00:00` to `24:00` is the whole day.
    convenience init(days: [QuietHoursDay]? = nil, start: String, end: String) {
        self.init(days: days, end: end, start: start)
    }
}

extension PushScheduleInput {
    /// Creates the request form of a schedule. It always sends every rule, so it replaces the stored schedule.
    convenience init(_ schedule: PushSchedule) {
        self.init(
            quietHours: schedule.quietHours.map {
                QuietHoursRuleInput(days: $0.days, end: $0.end, start: $0.start)
            },
            timezone: schedule.timezone
        )
    }
}

extension ClientError {
    /// The server did not store the quiet hours schedule, because it does not support quiet hours yet.
    public final class QuietHoursNotStored: ClientError, @unchecked Sendable {
        override public var localizedDescription: String {
            "The quiet hours schedule was not stored. The server does not support quiet hours yet."
        }
    }

    /// The quiet hours schedule has no rules. Use `removeQuietHours()` to remove the schedule.
    public final class QuietHoursEmpty: ClientError, @unchecked Sendable {
        override public var localizedDescription: String {
            "The quiet hours schedule has no rules. Use `removeQuietHours()` to remove the schedule."
        }
    }
}

//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A recurring quiet hours schedule for the current user's push notifications.
///
/// While any of the quiet windows is active, the server drops the user's chat push notifications.
public struct PushSchedule: Hashable, Sendable {
    /// The quiet windows. Push notifications are dropped while any of them is active.
    public let quietHours: [QuietHoursRule]
    /// The time zone the quiet windows are evaluated in.
    public let timezone: TimeZone

    /// Creates a quiet hours schedule.
    /// - Parameters:
    ///   - quietHours: The quiet windows, 1 to 7 rules.
    ///   - timezone: The time zone the quiet windows are evaluated in. Defaults to the device's time zone.
    ///   It must be a named time zone, such as `Europe/Amsterdam`: the server rejects fixed-offset
    ///   time zones created with `TimeZone(secondsFromGMT:)`.
    public init(quietHours: [QuietHoursRule], timezone: TimeZone = .current) {
        self.quietHours = quietHours
        self.timezone = timezone
    }
}

extension PushSchedule: Codable {
    private enum CodingKeys: String, CodingKey {
        case quietHours = "quiet_hours"
        case timezone
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        quietHours = try container.decode([QuietHoursRule].self, forKey: .quietHours)
        // A zone this device does not know falls back to the device's zone instead of failing the push preference.
        timezone = TimeZone(identifier: try container.decode(String.self, forKey: .timezone)) ?? .current
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(quietHours, forKey: .quietHours)
        try container.encode(timezone.identifier, forKey: .timezone)
    }
}

extension PushScheduleInput {
    /// Creates the request form of a schedule. It always sends every rule, so it replaces the stored schedule.
    convenience init(_ schedule: PushSchedule) {
        self.init(
            quietHours: schedule.quietHours.map {
                QuietHoursRuleInput(days: $0.days, end: $0.end, start: $0.start)
            },
            timezone: schedule.timezone.identifier
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

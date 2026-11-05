//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A recurring quiet-hours schedule: while any quiet window is active, push notifications for the user are suppressed. Suppressed notifications are dropped, not delayed.
public final class PushSchedule: Sendable, Codable, JSONEncodable {
    /// The quiet windows. Push is suppressed while any rule is active.
    public let quietHours: [QuietHoursRule]
    /// IANA time zone name the quiet windows are evaluated in, for example Europe/Amsterdam.
    public let timezone: String

    init(quietHours: [QuietHoursRule], timezone: String) {
        self.quietHours = quietHours
        self.timezone = timezone
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.quietHours = try container.decode([QuietHoursRule].self, forKey: .quietHours)
        self.timezone = try container.decode(String.self, forKey: .timezone)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(quietHours, forKey: .quietHours)
        try container.encode(timezone, forKey: .timezone)
    }
}

extension PushSchedule: Hashable {
    public static func == (lhs: PushSchedule, rhs: PushSchedule) -> Bool {
        lhs.quietHours == rhs.quietHours &&
            lhs.timezone == rhs.timezone
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(quietHours)
        hasher.combine(timezone)
    }
}

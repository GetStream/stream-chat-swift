//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A recurring quiet window, in the local wall-clock time of the schedule's time zone.
///
/// A window belongs to the day it opens on: `[.friday]` from `"22:00"` to `"07:00"`
/// is quiet from Friday 22:00 until Saturday 07:00.
public struct QuietHoursRule: Hashable, Sendable, Codable {
    /// The days the window opens on. `nil` or empty means every day.
    public let days: [QuietHoursDay]?
    /// When the window opens, as `HH:mm` between `00:00` and `23:59`.
    public let start: String
    /// When the window closes (exclusive), as `HH:mm` between `00:00` and `24:00`.
    /// An end earlier than the start wraps past midnight. `00:00` to `24:00` is the whole day.
    public let end: String

    /// Creates a recurring quiet window.
    /// - Parameters:
    ///   - days: The days the window opens on. `nil` or empty means every day.
    ///   - start: When the window opens, as `HH:mm` between `00:00` and `23:59`.
    ///   - end: When the window closes (exclusive), as `HH:mm` between `00:00` and `24:00`.
    public init(days: [QuietHoursDay]? = nil, start: String, end: String) {
        self.days = days
        self.start = start
        self.end = end
    }

    private enum CodingKeys: String, CodingKey {
        case days
        case start
        case end
    }
}

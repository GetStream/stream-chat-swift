//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A day of the week a quiet hours window opens on.
public struct QuietHoursDay: RawRepresentable, Codable, Hashable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }

    public static let monday = QuietHoursDay(rawValue: "mon")
    public static let tuesday = QuietHoursDay(rawValue: "tue")
    public static let wednesday = QuietHoursDay(rawValue: "wed")
    public static let thursday = QuietHoursDay(rawValue: "thu")
    public static let friday = QuietHoursDay(rawValue: "fri")
    public static let saturday = QuietHoursDay(rawValue: "sat")
    public static let sunday = QuietHoursDay(rawValue: "sun")

    /// Monday to Friday.
    public static let weekdays: [QuietHoursDay] = [.monday, .tuesday, .wednesday, .thursday, .friday]
    /// Saturday and Sunday.
    public static let weekend: [QuietHoursDay] = [.saturday, .sunday]
}

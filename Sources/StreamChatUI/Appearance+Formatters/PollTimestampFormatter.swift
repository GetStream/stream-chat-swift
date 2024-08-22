//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// A formatter that converts the poll timestamps to textual representation.
public protocol PollTimestampFormatter {
    func formatDay(_ date: Date) -> String
    func formatTime(_ date: Date) -> String
}

/// The poll timestamp formatter used in poll votes and comments.
open class DefaultPollTimestampFormatter: PollTimestampFormatter {
    /// The formatter to show the day.
    public var dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.setLocalizedDateFormatFromTemplate("dd/MM/YY")
        return formatter
    }()

    /// The formatter to show the date and time.
    public var timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.setLocalizedDateFormatFromTemplate("HH:mm a")
        return formatter
    }()

    /// The formatter to show "Today" in case the message was sent the current day.
    public var relativeDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        formatter.doesRelativeDateFormatting = true
        return formatter
    }()

    /// The formatter to show the week day.
    public var weekDayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.setLocalizedDateFormatFromTemplate("EEEE")
        return formatter
    }()

    var calendar: StreamCalendar = Calendar.current

    public init() {}

    open func formatDay(_ date: Date) -> String {
        if calendar.isDateInToday(date) || calendar.isDateInYesterday(date) {
            return relativeDateFormatter.string(from: date)
        }

        if calendar.isDateInLastWeek(date) {
            return weekDayDateFormatter.string(from: date)
        }

        return dayFormatter.string(from: date)
    }

    open func formatTime(_ date: Date) -> String {
        timeFormatter.string(from: date)
    }
}

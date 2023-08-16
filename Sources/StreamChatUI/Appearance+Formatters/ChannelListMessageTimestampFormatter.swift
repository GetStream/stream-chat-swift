//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

/// The last message timestamp formatter in channel list.
open class ChannelListMessageTimestampFormatter: MessageTimestampFormatter {
    /// The formatter to show the time that a message was sent if it was sent today.
    public var timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.locale = .autoupdatingCurrent
        return formatter
    }()

    /// The formatter to show "Yesterday" in case the message was sent yesterday.
    public var relativeDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        formatter.doesRelativeDateFormatting = true
        formatter.locale = .autoupdatingCurrent
        return formatter
    }()

    /// The formatter to show the week day that a message was sent.
    public var weekDayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("EEEE")
        formatter.locale = .autoupdatingCurrent
        return formatter
    }()

    /// The formatter to show the date that a message was sent in case it was sent before the last week.
    public var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        formatter.locale = .autoupdatingCurrent
        return formatter
    }()

    public let calendar: Calendar

    public init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    open func format(_ date: Date) -> String {
        if calendar.isDateInToday(date) {
            return timeFormatter.string(from: date)
        }
        if calendar.isDateInYesterday(date) {
            return relativeDateFormatter.string(from: date)
        }
        if calendar.isDateInLastWeek(date) {
            return weekDayDateFormatter.string(from: date)
        }

        return dateFormatter.string(from: date)
    }
}

private extension Calendar {
    func isDateInLastWeek(_ date: Date) -> Bool {
        guard let dateBefore7days = self.date(byAdding: .day, value: -7, to: Date()) else {
            return false
        }

        return date > dateBefore7days
    }
}

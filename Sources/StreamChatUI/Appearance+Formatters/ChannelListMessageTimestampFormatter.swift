//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// The last message timestamp formatter in channel list.
open class ChannelListMessageTimestampFormatter: MessageTimestampFormatter {
    /// The formatter to show the time that a message was sent if it was sent today.
    public var timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    /// The formatter to show "Yesterday" in case the message was sent yesterday.
    public var relativeDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        formatter.doesRelativeDateFormatting = true
        return formatter
    }()

    /// The formatter to show the week day that a message was sent.
    public var weekDayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.setLocalizedDateFormatFromTemplate("EEEE")
        return formatter
    }()

    /// The formatter to show the date that a message was sent in case it was sent before the last week.
    public var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()

    var calendar: StreamCalendar = Calendar.current

    public init() {}

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

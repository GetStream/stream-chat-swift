//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A formatter that converts the date a scheduled message is sent at to textual representation.
public protocol ScheduledMessageDateFormatter {
    /// Formats the date and time a scheduled message is sent at, for example "Tomorrow at 09:00".
    func format(_ date: Date) -> String
    /// Formats a short name of the time zone, for example "GMT+3".
    func formatTimeZone(_ timeZone: TimeZone) -> String
}

/// The default scheduled message date formatter.
///
/// Formatting rules for the day, which is followed by the time:
/// - Same day: "Today"
/// - Next day: "Tomorrow"
/// - 2–6 days ahead: the weekday, for example "Monday"
/// - Another day of the current year: "Fri, Oct 23"
/// - Another year: "Fri, Oct 23, 2027"
open class DefaultScheduledMessageDateFormatter: ScheduledMessageDateFormatter {
    /// The calendar used to tell how far the date is from now.
    public let calendar: Calendar

    /// The formatter to show relative dates like "Today" or "Tomorrow".
    public var relativeDateFormatter: DateFormatter

    /// The formatter to show the weekday.
    public var weekdayFormatter: DateFormatter

    /// The formatter to show the day of a date in the current year.
    public var dayFormatter: DateFormatter

    /// The formatter to show the day of a date in another year.
    public var dayWithYearFormatter: DateFormatter

    /// The formatter to show the time.
    public var timeFormatter: DateFormatter

    /// The formatter to show the short name of a time zone.
    public var timeZoneFormatter: DateFormatter

    /// Creates the formatter.
    /// - Parameters:
    ///   - calendar: The calendar used to tell how far the date is from now. The dates are shown in its time zone.
    ///   - locale: The locale of the formatted text.
    public init(calendar: Calendar = .autoupdatingCurrent, locale: Locale = .autoupdatingCurrent) {
        self.calendar = calendar
        let makeFormatter: (String?) -> DateFormatter = { template in
            let formatter = DateFormatter()
            formatter.calendar = calendar
            formatter.timeZone = calendar.timeZone
            formatter.locale = locale
            if let template {
                formatter.setLocalizedDateFormatFromTemplate(template)
            }
            return formatter
        }
        relativeDateFormatter = makeFormatter(nil)
        relativeDateFormatter.dateStyle = .medium
        relativeDateFormatter.timeStyle = .none
        relativeDateFormatter.doesRelativeDateFormatting = true
        weekdayFormatter = makeFormatter("EEEE")
        dayFormatter = makeFormatter("EEEMMMd")
        dayWithYearFormatter = makeFormatter("EEEMMMdy")
        timeFormatter = makeFormatter(nil)
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short
        timeZoneFormatter = makeFormatter(nil)
        timeZoneFormatter.dateFormat = "O"
        // The day starts the text, so it is capitalized in every locale.
        [relativeDateFormatter, weekdayFormatter, dayFormatter, dayWithYearFormatter].forEach {
            $0.formattingContext = .beginningOfSentence
        }
    }

    open func format(_ date: Date) -> String {
        L10n.ScheduledMessage.Date.dayAtTime(formatDay(date), timeFormatter.string(from: date))
    }

    open func formatTimeZone(_ timeZone: TimeZone) -> String {
        timeZoneFormatter.timeZone = timeZone
        return timeZoneFormatter.string(from: Date())
    }

    private func formatDay(_ date: Date) -> String {
        let now = Date()
        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: now),
            to: calendar.startOfDay(for: date)
        ).day ?? 0
        switch days {
        case 0...1:
            return relativeDateFormatter.string(from: date)
        case 2...6:
            return weekdayFormatter.string(from: date)
        default:
            let isCurrentYear = calendar.isDate(date, equalTo: now, toGranularity: .year)
            return (isCurrentYear ? dayFormatter : dayWithYearFormatter).string(from: date)
        }
    }
}

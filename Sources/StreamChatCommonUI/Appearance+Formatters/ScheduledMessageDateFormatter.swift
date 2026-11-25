//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A formatter that converts the date a scheduled message is sent at to textual representation.
public protocol ScheduledMessageDateFormatter {
    /// Formats the date and time a scheduled message is sent at, for example "Tomorrow at 09:00".
    func format(_ date: Date) -> String
    /// Formats the date and time a scheduled message is sent at without relative days, for example "Wed, Oct 21 at 09:00".
    func formatAbsolute(_ date: Date) -> String
    /// Formats a short name of the time zone, for example "GMT+3".
    func formatTimeZone(_ timeZone: TimeZone) -> String
}

/// The default scheduled message date formatter.
///
/// Formatting rules for the day, which is followed by the time:
/// - A day up to 6 days ahead that the locale has a name for: the name, for example "Today", "Tomorrow" or the French "Après-demain"
/// - Another day up to 6 days ahead: the weekday, for example "Monday"
/// - Another day of the current year: "Fri, Oct 23"
/// - Another year: "Fri, Oct 23, 2027"
open class DefaultScheduledMessageDateFormatter: ScheduledMessageDateFormatter {
    private let calendar: Calendar
    private let relativeDateFormatter: DateFormatter
    private let dateFormatter: DateFormatter
    private let weekdayFormatter: DateFormatter
    private let dayFormatter: DateFormatter
    private let dayWithYearFormatter: DateFormatter
    private let timeFormatter: DateFormatter
    private let timeZoneFormatter: DateFormatter

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
        dateFormatter = makeFormatter(nil)
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        weekdayFormatter = makeFormatter("EEEE")
        dayFormatter = makeFormatter("EEEMMMd")
        dayWithYearFormatter = makeFormatter("EEEMMMdy")
        timeFormatter = makeFormatter(nil)
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short
        timeZoneFormatter = makeFormatter(nil)
        timeZoneFormatter.dateFormat = "O"
        // The day starts the text, so it is capitalized in every locale. The date without a relative name is compared
        // with the relative day, so it uses the same context.
        [relativeDateFormatter, dateFormatter, weekdayFormatter, dayFormatter, dayWithYearFormatter].forEach {
            $0.formattingContext = .beginningOfSentence
        }
    }

    open func format(_ date: Date) -> String {
        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: Date()),
            to: calendar.startOfDay(for: date)
        ).day ?? 0
        let day: String
        switch days {
        case 0...6:
            // Locales name a different number of days, for example the French "après-demain".
            let relativeDay = relativeDateFormatter.string(from: date)
            day = relativeDay != dateFormatter.string(from: date) ? relativeDay : weekdayFormatter.string(from: date)
        default:
            day = formatAbsoluteDay(date)
        }
        return L10n.ScheduledMessage.Date.dayAtTime(day, timeFormatter.string(from: date))
    }

    open func formatAbsolute(_ date: Date) -> String {
        L10n.ScheduledMessage.Date.dayAtTime(formatAbsoluteDay(date), timeFormatter.string(from: date))
    }

    open func formatTimeZone(_ timeZone: TimeZone) -> String {
        timeZoneFormatter.timeZone = timeZone
        return timeZoneFormatter.string(from: Date())
    }

    private func formatAbsoluteDay(_ date: Date) -> String {
        let isCurrentYear = calendar.isDate(date, equalTo: Date(), toGranularity: .year)
        return (isCurrentYear ? dayFormatter : dayWithYearFormatter).string(from: date)
    }
}

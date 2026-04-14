//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A formatter that converts the poll timestamps to textual representation.
public protocol PollTimestampFormatter {
    func formatDay(_ date: Date) -> String
    func formatTime(_ date: Date) -> String
}

/// The poll timestamp formatter used in poll votes and comments.
///
/// Formatting rules for `formatDay`:
/// - Same day: "Today"
/// - 1 day ago: "Yesterday"
/// - 2–6 days ago: "Nd ago"
/// - 1–3 weeks ago: "Nw ago"
/// - 4+ weeks: DD/MM/YY
open class DefaultPollTimestampFormatter: PollTimestampFormatter {
    /// The formatter to show the day in DD/MM/YY format.
    public var dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.setLocalizedDateFormatFromTemplate("dd/MM/YY")
        return formatter
    }()

    /// The formatter to show the time.
    public var timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.setLocalizedDateFormatFromTemplate("HH:mm a")
        return formatter
    }()

    /// The formatter to show relative dates like "Today" or "Yesterday".
    public var relativeDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        formatter.doesRelativeDateFormatting = true
        return formatter
    }()

    var calendar: StreamCalendar = Calendar.current

    public init() {}

    open func formatDay(_ date: Date) -> String {
        if calendar.isDateInToday(date) || calendar.isDateInYesterday(date) {
            return relativeDateFormatter.string(from: date)
        }

        let days = Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: date),
            to: Calendar.current.startOfDay(for: Date())
        ).day ?? 0

        if days >= 2 && days <= 6 {
            return L10n.Message.Polls.Date.daysAgo(days)
        }

        if days >= 7 {
            let weeks = days / 7
            if weeks <= 3 {
                return L10n.Message.Polls.Date.weeksAgo(weeks)
            }
        }

        return dayFormatter.string(from: date)
    }

    open func formatTime(_ date: Date) -> String {
        timeFormatter.string(from: date)
    }
}

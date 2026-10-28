//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

enum DemoScheduledDateFormatter {
    static func string(from date: Date, now: Date = Date(), calendar: Calendar = .current) -> String {
        "\(dayString(from: date, now: now, calendar: calendar)) at \(timeString(from: date))"
    }

    static var timeZoneDescription: String {
        let timeZone = TimeZone.current
        let style: NSTimeZone.NameStyle = timeZone.isDaylightSavingTime() ? .daylightSaving : .standard
        return timeZone.localizedName(for: style, locale: .current) ?? timeZone.identifier
    }

    private static func dayString(from date: Date, now: Date, calendar: Calendar) -> String {
        if calendar.isDate(date, inSameDayAs: now) {
            return "Today"
        }
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now), calendar.isDate(date, inSameDayAs: tomorrow) {
            return "Tomorrow"
        }

        let formatter = DateFormatter()
        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: now),
            to: calendar.startOfDay(for: date)
        ).day ?? 0
        if (2..<7).contains(days) {
            formatter.setLocalizedDateFormatFromTemplate("EEEE")
        } else if calendar.isDate(date, equalTo: now, toGranularity: .year) {
            formatter.setLocalizedDateFormatFromTemplate("EEEMMMd")
        } else {
            formatter.setLocalizedDateFormatFromTemplate("EEEMMMdy")
        }
        return formatter.string(from: date)
    }

    private static func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

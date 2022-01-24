//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

class DateUtils {
    /// timeAgo formats a date into a string like "15 minutes ago"
    static func timeAgo(relativeTo date: Date) -> String? {
        let now = Date()
        let calendar = Calendar.current

        if now < date {
            return nil
        }

        guard
            let minuteAgo = calendar.date(byAdding: .minute, value: -1, to: now),
            let hourAgo = calendar.date(byAdding: .hour, value: -1, to: now),
            let dayAgo = calendar.date(byAdding: .day, value: -1, to: now),
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: now),
            let monthAgo = calendar.date(byAdding: .month, value: -1, to: now)
        else { return nil }
        
        if minuteAgo < date {
            let diff = calendar.dateComponents([.second], from: date, to: now).second ?? 0
            return diff > 1 ? L10n.Dates.timeAgoSecondsPlural(diff) : L10n.Dates.timeAgoSecondsSingular
        }
        
        if hourAgo < date {
            let diff = calendar.dateComponents([.minute], from: date, to: now).minute ?? 0
            return diff > 1 ? L10n.Dates.timeAgoMinutesPlural(diff) : L10n.Dates.timeAgoMinutesSingular
        }
        
        if dayAgo < date {
            let diff = calendar.dateComponents([.hour], from: date, to: now).hour ?? 0
            return diff > 1 ? L10n.Dates.timeAgoHoursPlural(diff) : L10n.Dates.timeAgoHoursSingular
        }
        
        if weekAgo < date {
            let diff = calendar.dateComponents([.day], from: date, to: now).day ?? 0
            return diff > 1 ? L10n.Dates.timeAgoDaysPlural(diff) : L10n.Dates.timeAgoDaysSingular
        }
        
        if monthAgo < date {
            let diff = calendar.dateComponents([.weekOfYear], from: date, to: now).weekOfYear ?? 0
            return diff > 1 ? L10n.Dates.timeAgoWeeksPlural(diff) : L10n.Dates.timeAgoWeeksSingular
        }

        let diff = calendar.dateComponents([.month], from: date, to: now).month ?? 0
        return diff > 1 ? L10n.Dates.timeAgoMonthsPlural(diff) : L10n.Dates.timeAgoMonthsSingular
    }
}

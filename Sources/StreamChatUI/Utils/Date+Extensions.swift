//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

extension Date {
    /// The code snippet is taken from [stackoverflow](https://stackoverflow.com/a/44087489)
    var timeAgo: String? {
        let now = Date()
        if #available(iOS 13.0, *) {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .full
            return formatter.localizedString(for: self, relativeTo: now)
        } else {
            let calendar = Calendar.current
            guard
                let minuteAgo = calendar.date(byAdding: .minute, value: -1, to: now),
                let hourAgo = calendar.date(byAdding: .hour, value: -1, to: now),
                let dayAgo = calendar.date(byAdding: .day, value: -1, to: now),
                let weekAgo = calendar.date(byAdding: .day, value: -7, to: now)
            else { return nil }
            
            if minuteAgo < self {
                let diff = calendar.dateComponents([.second], from: self, to: now).second ?? 0
                return "\(diff) sec ago"
            } else if hourAgo < self {
                let diff = calendar.dateComponents([.minute], from: self, to: now).minute ?? 0
                return "\(diff) min ago"
            } else if dayAgo < self {
                let diff = calendar.dateComponents([.hour], from: self, to: now).hour ?? 0
                return "\(diff) hrs ago"
            } else if weekAgo < self {
                let diff = calendar.dateComponents([.day], from: self, to: now).day ?? 0
                return "\(diff) days ago"
            } else {
                let diff = calendar.dateComponents([.weekOfYear], from: self, to: now).weekOfYear ?? 0
                return "\(diff) weeks ago"
            }
        }
    }

    func toLocalTime() -> Date {
        let timezone = TimeZone.current
        let seconds = TimeInterval(timezone.secondsFromGMT(for: self))
        return Date(timeInterval: seconds, since: self)
    }

    func minutesFromCurrentDate(_ oldDate: Date) -> Float {
        let newDateMinutes = Date().timeIntervalSinceReferenceDate/60
        let oldDateMinutes = oldDate.timeIntervalSinceReferenceDate/60
        return Float(oldDateMinutes - newDateMinutes)
    }

    func withAddedMinutes(minutes: Double) -> Date {
        addingTimeInterval(minutes * 60)
    }

    func withAddedHours(hours: Double) -> Date {
        withAddedMinutes(minutes: hours * 60)
    }

    var ticks: Double {
        //return Int64(self.timeIntervalSince1970 * 1000)
        return timeIntervalSince1970
    }
}

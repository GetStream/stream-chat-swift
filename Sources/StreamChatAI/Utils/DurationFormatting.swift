//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

enum DurationFormatting {
    static func minutesAndSeconds(_ seconds: Int, locale: Locale = .autoupdatingCurrent) -> String {
        if #available(iOS 16.0, *) {
            return Duration.seconds(seconds)
                .formatted(.units(allowed: [.minutes, .seconds], width: .narrow).locale(locale))
        }
        var calendar = Calendar.current
        calendar.locale = locale
        let formatter = DateComponentsFormatter()
        formatter.calendar = calendar
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: TimeInterval(seconds)) ?? "\(seconds)s"
    }
}

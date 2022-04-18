//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

public extension Calendar {
    static var gmtCalendar: Calendar {
        // Create a GMT calendar, to test on GMT+0 timezone
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }
}

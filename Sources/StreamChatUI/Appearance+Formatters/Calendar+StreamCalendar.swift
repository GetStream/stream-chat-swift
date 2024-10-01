//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

protocol StreamCalendar {
    func isDateInToday(_ date: Date) -> Bool
    func isDateInYesterday(_ date: Date) -> Bool
    func isDateInLastWeek(_ date: Date) -> Bool
}

extension Calendar: StreamCalendar {
    func isDateInLastWeek(_ date: Date) -> Bool {
        guard let dateBefore7days = self.date(byAdding: .day, value: -7, to: Date()) else {
            return false
        }

        return date > dateBefore7days
    }
}

//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
@testable import StreamChatUI

class Calendar_Mock: StreamCalendar {
    var mockIsDateInToday = false
    var mockIsDateInYesterday = false
    var mockIsDateInLastWeek = false

    func isDateInToday(_ date: Date) -> Bool {
        mockIsDateInToday
    }

    func isDateInYesterday(_ date: Date) -> Bool {
        mockIsDateInYesterday
    }

    func isDateInLastWeek(_ date: Date) -> Bool {
        mockIsDateInLastWeek
    }
}

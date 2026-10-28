//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Status of a scheduled message.
final class ScheduledMessageServerStatus: RawRepresentable, Decodable, Hashable, Sendable {
    let rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue
    }

    static let canceled = ScheduledMessageServerStatus(rawValue: "canceled")
    static let failed = ScheduledMessageServerStatus(rawValue: "failed")
    static let scheduled = ScheduledMessageServerStatus(rawValue: "scheduled")
    static let sending = ScheduledMessageServerStatus(rawValue: "sending")
    static let sent = ScheduledMessageServerStatus(rawValue: "sent")
}

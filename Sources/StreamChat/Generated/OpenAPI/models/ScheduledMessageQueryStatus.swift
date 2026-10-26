//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Status filter for querying scheduled messages.
final class ScheduledMessageQueryStatus: RawRepresentable, Encodable, Hashable, Sendable {
    let rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue
    }

    static let failed = ScheduledMessageQueryStatus(rawValue: "failed")
    static let scheduled = ScheduledMessageQueryStatus(rawValue: "scheduled")
    static let sending = ScheduledMessageQueryStatus(rawValue: "sending")
}

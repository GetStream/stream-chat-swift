//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The status of a scheduled message.
public struct ScheduledMessageStatus: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }

    /// The message waits to be sent at `scheduledAt`.
    public static let scheduled: Self = "scheduled"

    /// The server is sending the message. It can no longer be edited, rescheduled or deleted.
    public static let sending: Self = "sending"

    /// The message could not be sent. See `ScheduledMessage.failureReason`.
    public static let failed: Self = "failed"
}

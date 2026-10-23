//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The error of the server when the local changes of a scheduled message could not be sent to it.
public struct ScheduledMessageLocalError: Hashable, Sendable {
    /// The reason of the error, when the server gives one.
    public let reason: ScheduledMessageErrorReason?

    /// The message of the server, which describes the error, for example with the limit that is reached.
    public let message: String

    /// Whether sending the same changes again can succeed without changing them.
    ///
    /// When a scheduling limit is reached, another scheduled message has to be sent or deleted first.
    /// When the date is too soon or too far, the message has to be rescheduled.
    public var isRetryable: Bool {
        switch reason {
        case .scheduledAtTooSoon, .scheduledAtTooFar, .scheduledLimitChannel, .scheduledLimitUser,
             .scheduledMessagesDisabled, .scheduledMessageIdTaken, .scheduledMessageNotEditable,
             .scheduledMessageAlreadySent, .scheduledMessageCanceled:
            return false
        default:
            return true
        }
    }

    init(reason: ScheduledMessageErrorReason?, message: String) {
        self.reason = reason
        self.message = message
    }
}

//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The reason the server rejects a scheduled message.
public struct ScheduledMessageErrorReason: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }

    /// Scheduled messages are disabled for the app.
    public static let scheduledMessagesDisabled: Self = "scheduled_messages_disabled"

    /// The new date of a scheduled message is in the past.
    public static let scheduledAtTooSoon: Self = "scheduled_at_too_soon"

    /// The date is further than the maximum lead time of the app.
    public static let scheduledAtTooFar: Self = "scheduled_at_too_far"

    /// The current user has as many pending scheduled messages in the channel as the app allows.
    public static let scheduledLimitChannel: Self = "scheduled_limit_channel"

    /// The current user has as many pending scheduled messages as the app allows.
    public static let scheduledLimitUser: Self = "scheduled_limit_user"

    /// The id of the scheduled message belongs to another user or channel.
    public static let scheduledMessageIdTaken: Self = "scheduled_message_id_taken"

    /// A failed scheduled message can not be edited.
    public static let scheduledMessageNotEditable: Self = "scheduled_message_not_editable"

    /// The server is sending the message, or will try again shortly.
    public static let scheduledMessageSending: Self = "scheduled_message_sending"

    /// Another edit was saved first.
    public static let scheduledMessageConflict: Self = "scheduled_message_conflict"

    /// The message was already sent at its date.
    public static let scheduledMessageAlreadySent: Self = "scheduled_message_already_sent"

    /// The scheduled message was deleted, for example on another device.
    public static let scheduledMessageCanceled: Self = "scheduled_message_canceled"
}

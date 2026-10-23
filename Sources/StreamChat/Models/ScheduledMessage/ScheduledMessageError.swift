//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Why a scheduled message has a problem, telling whether the server or the local device failed.
public enum ScheduledMessageError: Hashable, Sendable {
    /// The server rejected scheduling, editing or rescheduling the message.
    ///
    /// For example, the scheduling limit of the channel is reached. The latest changes are kept locally.
    case serverRejectedScheduling(ServerRejection)

    /// The server could not publish the message at `scheduledAt`, for example because the user was banned.
    ///
    /// The message can only be deleted, or scheduled again as a new message.
    case serverFailedPublishing(PublishingFailure)

    /// The local device failed to schedule, edit or reschedule the message, for example because an attachment
    /// could not be uploaded.
    ///
    /// A lost connection is not an error: the changes stay pending and are sent once the device is online.
    case localDeviceFailedScheduling(LocalFailure)

    /// Whether sending the same changes again can succeed without changing them.
    public var isRetryable: Bool {
        switch self {
        case let .serverRejectedScheduling(rejection):
            return rejection.isRetryable
        case .serverFailedPublishing:
            return false
        case .localDeviceFailedScheduling:
            return true
        }
    }
}

// MARK: - Server Rejection

public extension ScheduledMessageError {
    /// The server rejected scheduling, editing or rescheduling a message.
    struct ServerRejection: Hashable, Sendable {
        /// The reason of the rejection, when the server gives one.
        public let reason: Reason?

        /// The message of the server, which describes the rejection, for example with the limit that is reached.
        public let message: String

        /// Whether sending the same changes again can succeed without changing them.
        ///
        /// When a scheduling limit is reached, another scheduled message has to be sent or deleted first.
        /// When the date is in the past or too far, the message has to be rescheduled.
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

        init(reason: Reason?, message: String) {
            self.reason = reason
            self.message = message
        }
    }
}

public extension ScheduledMessageError.ServerRejection {
    /// The reason the server rejects scheduling, editing or rescheduling a message.
    struct Reason: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
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
}

// MARK: - Publishing Failure

public extension ScheduledMessageError {
    /// The server could not publish a scheduled message at its date.
    struct PublishingFailure: Hashable, Sendable {
        /// The reason of the failure, when the server gives one.
        public let reason: Reason?

        init(reason: Reason?) {
            self.reason = reason
        }
    }
}

public extension ScheduledMessageError.PublishingFailure {
    /// The reason the server could not publish a scheduled message.
    struct Reason: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
        public let rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        public init(stringLiteral value: String) {
            self.init(rawValue: value)
        }

        /// The current user is banned from the channel.
        public static let banned: Self = "banned"

        /// The current user is no longer allowed to send messages to the channel.
        public static let noPermission: Self = "no_permission"

        /// The channel is frozen.
        public static let channelFrozen: Self = "channel_frozen"

        /// The channel was deleted.
        public static let channelDeleted: Self = "channel_deleted"

        /// The current user was deleted.
        public static let userDeleted: Self = "user_deleted"

        /// Moderation blocked the message.
        public static let moderationBlocked: Self = "moderation_blocked"

        /// A before-message-send hook rejected the message.
        public static let hookRejected: Self = "hook_rejected"

        /// The server could not send the message within an hour of `scheduledAt`.
        public static let expired: Self = "expired"

        /// The message no longer meets the app's limits, for example its length.
        public static let invalidMessage: Self = "invalid_message"

        /// The server failed to send the message.
        public static let internalError: Self = "internal_error"
    }
}

// MARK: - Local Failure

public extension ScheduledMessageError {
    /// The local device could not send the changes of a scheduled message to the server.
    struct LocalFailure: Hashable, Sendable {
        /// The reason of the failure.
        public let reason: Reason

        /// A description of the underlying error, when there is one.
        public let message: String?

        init(reason: Reason, message: String? = nil) {
            self.reason = reason
            self.message = message
        }
    }
}

public extension ScheduledMessageError.LocalFailure {
    /// The reason the local device could not send the changes of a scheduled message.
    struct Reason: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
        public let rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        public init(stringLiteral value: String) {
            self.init(rawValue: value)
        }

        /// An attachment of the message could not be uploaded.
        public static let attachmentUploadFailed: Self = "attachment_upload_failed"

        /// The request failed without a response from the server.
        public static let requestFailed: Self = "request_failed"
    }
}

//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A message the server sends to a channel at `scheduledAt`.
///
/// Until it is sent, the current user can edit, reschedule, send now or delete it. Other channel members
/// see nothing until it is sent, and then it arrives as a regular message.
public final class ScheduledMessage: Identifiable, Equatable, @unchecked Sendable {
    /// The unique identifier of the scheduled message.
    ///
    /// It is also the identifier of `message`, and not necessarily the one of the message created when it is sent.
    public let id: String

    /// The channel the message is sent to.
    public let cid: ChannelId

    /// The channel the message is sent to, if it is available locally.
    public let channel: ChatChannel?

    /// The message that will be sent, so it can be rendered like any other message.
    ///
    /// It is authored by the current user, and its `createdAt` is `scheduledAt`. It is not part of the channel,
    /// and has no reactions, replies or read state. Users and the quoted message are only fully populated
    /// when they are available locally.
    public let message: ChatMessage

    /// The identifier of the message quoted by `message`, even when the quoted message is not available locally.
    public let quotedMessageId: MessageId?

    /// The date when the message is sent.
    public let scheduledAt: Date

    /// The current status of the scheduled message.
    public let status: ScheduledMessageStatus

    /// Why the message could not be sent, when `status` is `.failed`.
    public let failureReason: ScheduledMessageFailureReason?

    /// The date when the message was scheduled.
    public let createdAt: Date

    /// The date when the message was last edited or rescheduled.
    public let updatedAt: Date

    /// Whether the message is still waiting to be sent, which is the case unless it failed.
    public var isPending: Bool {
        status != .failed
    }

    init(
        id: String,
        cid: ChannelId,
        channel: ChatChannel?,
        message: ChatMessage,
        quotedMessageId: MessageId?,
        scheduledAt: Date,
        status: ScheduledMessageStatus,
        failureReason: ScheduledMessageFailureReason?,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.cid = cid
        self.channel = channel
        self.message = message
        self.quotedMessageId = quotedMessageId
        self.scheduledAt = scheduledAt
        self.status = status
        self.failureReason = failureReason
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public static func == (lhs: ScheduledMessage, rhs: ScheduledMessage) -> Bool {
        lhs.id == rhs.id
            && lhs.cid == rhs.cid
            && lhs.message.text == rhs.message.text
            && lhs.message.allAttachments == rhs.message.allAttachments
            && lhs.message.mentionedUsers.map(\.id).sorted() == rhs.message.mentionedUsers.map(\.id).sorted()
            && lhs.quotedMessageId == rhs.quotedMessageId
            && lhs.message.parentMessageId == rhs.message.parentMessageId
            && lhs.message.showReplyInChannel == rhs.message.showReplyInChannel
            && lhs.message.extraData == rhs.message.extraData
            && lhs.scheduledAt == rhs.scheduledAt
            && lhs.status == rhs.status
            && lhs.failureReason == rhs.failureReason
            && lhs.createdAt == rhs.createdAt
            && lhs.updatedAt == rhs.updatedAt
    }
}

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

/// The reason a scheduled message could not be sent.
public struct ScheduledMessageFailureReason: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
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

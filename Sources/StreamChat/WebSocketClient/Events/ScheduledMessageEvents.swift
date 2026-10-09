//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Triggered when the current user schedules a message.
///
/// Scheduled message events are only sent to the current user's own connections.
public final class ScheduledMessageCreatedEvent: Event {
    /// The scheduled message.
    public let scheduledMessage: ScheduledMessage

    /// The channel the message is scheduled for.
    public var cid: ChannelId { scheduledMessage.cid }

    /// The event timestamp.
    public let createdAt: Date

    init(scheduledMessage: ScheduledMessage, createdAt: Date) {
        self.scheduledMessage = scheduledMessage
        self.createdAt = createdAt
    }
}

/// Triggered when the current user edits or reschedules a scheduled message, or when the server starts sending it.
public final class ScheduledMessageUpdatedEvent: Event {
    /// The updated scheduled message.
    public let scheduledMessage: ScheduledMessage

    /// The channel the message is scheduled for.
    public var cid: ChannelId { scheduledMessage.cid }

    /// The event timestamp.
    public let createdAt: Date

    init(scheduledMessage: ScheduledMessage, createdAt: Date) {
        self.scheduledMessage = scheduledMessage
        self.createdAt = createdAt
    }
}

/// Triggered when the current user deletes a scheduled message.
public final class ScheduledMessageDeletedEvent: Event {
    /// The deleted scheduled message.
    public let scheduledMessage: ScheduledMessage

    /// The channel the message was scheduled for.
    public var cid: ChannelId { scheduledMessage.cid }

    /// The event timestamp.
    public let createdAt: Date

    init(scheduledMessage: ScheduledMessage, createdAt: Date) {
        self.scheduledMessage = scheduledMessage
        self.createdAt = createdAt
    }
}

/// Triggered when the server sends a scheduled message.
///
/// The sent message arrives through the regular new message event, in either order.
public final class ScheduledMessageSentEvent: Event {
    /// The scheduled message that was sent.
    public let scheduledMessage: ScheduledMessage

    /// The identifier of the message created when it was sent.
    public let messageId: MessageId

    /// The channel the message was sent to.
    public var cid: ChannelId { scheduledMessage.cid }

    /// The event timestamp.
    public let createdAt: Date

    init(scheduledMessage: ScheduledMessage, messageId: MessageId, createdAt: Date) {
        self.scheduledMessage = scheduledMessage
        self.messageId = messageId
        self.createdAt = createdAt
    }
}

/// Triggered when the server could not send a scheduled message.
public final class ScheduledMessageFailedEvent: Event {
    /// The scheduled message that failed, with its `failureReason`.
    public let scheduledMessage: ScheduledMessage

    /// The channel the message was scheduled for.
    public var cid: ChannelId { scheduledMessage.cid }

    /// The event timestamp.
    public let createdAt: Date

    init(scheduledMessage: ScheduledMessage, createdAt: Date) {
        self.scheduledMessage = scheduledMessage
        self.createdAt = createdAt
    }
}

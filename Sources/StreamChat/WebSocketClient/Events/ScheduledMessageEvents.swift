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

extension ScheduledMessageCreatedEventDTO: EventDTO {
    func toDomainEvent(session: any DatabaseSession) -> Event? {
        guard
            let payload = scheduledMessage,
            let scheduledMessage = try? session.saveScheduledMessage(payload: payload).asModel()
        else { return nil }
        return ScheduledMessageCreatedEvent(scheduledMessage: scheduledMessage, createdAt: createdAt)
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

extension ScheduledMessageUpdatedEventDTO: EventDTO {
    func toDomainEvent(session: any DatabaseSession) -> Event? {
        guard
            let payload = scheduledMessage,
            let scheduledMessage = try? session.saveScheduledMessage(payload: payload).asModel()
        else { return nil }
        return ScheduledMessageUpdatedEvent(scheduledMessage: scheduledMessage, createdAt: createdAt)
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

extension ScheduledMessageDeletedEventDTO: EventDTO {
    func toDomainEvent(session: any DatabaseSession) -> Event? {
        guard
            let payload = scheduledMessage,
            let scheduledMessage = try? session.saveScheduledMessage(payload: payload).asModel()
        else { return nil }
        session.deleteScheduledMessage(id: payload.id)
        return ScheduledMessageDeletedEvent(scheduledMessage: scheduledMessage, createdAt: createdAt)
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

extension ScheduledMessageSentEventDTO: EventDTO {
    func toDomainEvent(session: any DatabaseSession) -> Event? {
        guard
            let payload = scheduledMessage,
            let scheduledMessage = try? session.saveScheduledMessage(payload: payload).asModel()
        else { return nil }
        session.deleteScheduledMessage(id: payload.id)
        return ScheduledMessageSentEvent(scheduledMessage: scheduledMessage, messageId: messageId, createdAt: createdAt)
    }
}

/// Triggered when the server could not send a scheduled message.
public final class ScheduledMessageFailedEvent: Event {
    /// The scheduled message that failed, with the reason in its `error`.
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

extension ScheduledMessageFailedEventDTO: EventDTO {
    func toDomainEvent(session: any DatabaseSession) -> Event? {
        guard
            let payload = scheduledMessage,
            let scheduledMessage = try? session.saveScheduledMessage(payload: payload).asModel()
        else { return nil }
        return ScheduledMessageFailedEvent(scheduledMessage: scheduledMessage, createdAt: createdAt)
    }
}

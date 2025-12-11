//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// Triggered when a message reminder is created.
public final class MessageReminderCreatedEvent: Event {
    /// The message ID associated with the reminder.
    public let messageId: MessageId
    
    /// The reminder that was created.
    public let reminder: MessageReminder
    
    /// The channel identifier where the reminder was created.
    public var cid: ChannelId { reminder.channel.cid }
    
    /// The event timestamp.
    public let createdAt: Date
    
    init(messageId: MessageId, reminder: MessageReminder, createdAt: Date) {
        self.messageId = messageId
        self.reminder = reminder
        self.createdAt = createdAt
    }
}

class ReminderCreatedEventDTO: EventDTO {
    let messageId: MessageId
    let reminder: ReminderPayload
    let createdAt: Date
    let payload: EventPayload
    
    init(from response: EventPayload) throws {
        messageId = try response.value(at: \.messageId)
        reminder = try response.value(at: \.reminder)
        createdAt = try response.value(at: \.createdAt)
        payload = response
    }
    
    func toDomainEvent(session: any DatabaseSession) -> Event? {
        guard
            let reminderDTO = try? session.saveReminder(payload: reminder, cache: nil),
            let reminderModel = try? reminderDTO.asModel()
        else { return nil }

        return MessageReminderCreatedEvent(
            messageId: messageId,
            reminder: reminderModel,
            createdAt: createdAt
        )
    }
}

/// Triggered when a message reminder is updated.
public final class MessageReminderUpdatedEvent: Event {
    /// The message ID associated with the reminder.
    public let messageId: MessageId
    
    /// The reminder that was updated.
    public let reminder: MessageReminder
    
    /// The channel identifier where the reminder was updated.
    public var cid: ChannelId { reminder.channel.cid }
    
    /// The event timestamp.
    public let createdAt: Date
    
    init(messageId: MessageId, reminder: MessageReminder, createdAt: Date) {
        self.messageId = messageId
        self.reminder = reminder
        self.createdAt = createdAt
    }
}

class ReminderUpdatedEventDTO: EventDTO {
    let messageId: MessageId
    let reminder: ReminderPayload
    let createdAt: Date
    let payload: EventPayload
    
    init(from response: EventPayload) throws {
        messageId = try response.value(at: \.messageId)
        reminder = try response.value(at: \.reminder)
        createdAt = try response.value(at: \.createdAt)
        payload = response
    }
    
    func toDomainEvent(session: any DatabaseSession) -> Event? {
        guard
            let reminderDTO = try? session.saveReminder(payload: reminder, cache: nil),
            let reminderModel = try? reminderDTO.asModel()
        else { return nil }

        return MessageReminderUpdatedEvent(
            messageId: messageId,
            reminder: reminderModel,
            createdAt: createdAt
        )
    }
}

/// Triggered when a message reminder is deleted.
public final class MessageReminderDeletedEvent: Event {
    /// The message ID associated with the reminder.
    public let messageId: MessageId
    
    /// The reminder information before deletion.
    public let reminder: MessageReminder
    
    /// The channel identifier where the reminder was deleted.
    public var cid: ChannelId { reminder.channel.cid }
    
    /// The event timestamp.
    public let createdAt: Date
    
    init(messageId: MessageId, reminder: MessageReminder, createdAt: Date) {
        self.messageId = messageId
        self.reminder = reminder
        self.createdAt = createdAt
    }
}

class ReminderDeletedEventDTO: EventDTO {
    let messageId: MessageId
    let reminder: ReminderPayload
    let createdAt: Date
    let payload: EventPayload
    
    init(from response: EventPayload) throws {
        messageId = try response.value(at: \.messageId)
        reminder = try response.value(at: \.reminder)
        createdAt = try response.value(at: \.createdAt)
        payload = response
    }
    
    func toDomainEvent(session: any DatabaseSession) -> Event? {
        // For deletion events, we need to construct the reminder model before deleting it
        guard
            let reminderDTO = try? session.saveReminder(payload: reminder, cache: nil),
            let reminderModel = try? reminderDTO.asModel()
        else { return nil }

        // Delete the reminder from the database
        session.deleteReminder(messageId: messageId)

        return MessageReminderDeletedEvent(
            messageId: messageId,
            reminder: reminderModel,
            createdAt: createdAt
        )
    }
}

/// Triggered when a reminder is due and a notification should be shown.
public final class MessageReminderDueEvent: Event {
    /// The message ID associated with the reminder.
    public let messageId: MessageId
    
    /// The reminder that is due.
    public let reminder: MessageReminder
    
    /// The channel identifier where the reminder is due.
    public var cid: ChannelId { reminder.channel.cid }
    
    /// The event timestamp.
    public let createdAt: Date
    
    init(messageId: MessageId, reminder: MessageReminder, createdAt: Date) {
        self.messageId = messageId
        self.reminder = reminder
        self.createdAt = createdAt
    }
}

class ReminderDueNotificationEventDTO: EventDTO {
    let messageId: MessageId
    let reminder: ReminderPayload
    let createdAt: Date
    let payload: EventPayload
    
    init(from response: EventPayload) throws {
        messageId = try response.value(at: \.messageId)
        reminder = try response.value(at: \.reminder)
        createdAt = try response.value(at: \.createdAt)
        payload = response
    }
    
    func toDomainEvent(session: any DatabaseSession) -> Event? {
        guard
            let reminderDTO = try? session.saveReminder(payload: reminder, cache: nil),
            let reminderModel = try? reminderDTO.asModel()
        else { return nil }

        return MessageReminderDueEvent(
            messageId: messageId,
            reminder: reminderModel,
            createdAt: createdAt
        )
    }
}

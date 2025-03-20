//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

@objc(MessageReminderDTO)
class MessageReminderDTO: NSManagedObject {
    @NSManaged var id: String
    @NSManaged var createdAt: DBDate
    @NSManaged var updatedAt: DBDate
    @NSManaged var remindAt: DBDate?

    // An helper property that is used for sorting the reminders when `remindAt` is not set.
    @NSManaged var sortingRemindAt: DBDate?

    // Relationships
    @NSManaged var message: MessageDTO
    @NSManaged var channel: ChannelDTO

    override func willSave() {
        super.willSave()

        let newSortingRemindAt = remindAt ?? .distantFuture.bridgeDate
        if sortingRemindAt != newSortingRemindAt {
            sortingRemindAt = newSortingRemindAt
        }
    }

    /// Returns a fetch request for a message reminder with the provided message ID.
    static func fetchRequest(messageId: MessageId) -> NSFetchRequest<MessageReminderDTO> {
        let request = NSFetchRequest<MessageReminderDTO>(entityName: MessageReminderDTO.entityName)
        request.predicate = NSPredicate(format: "message.id == %@", messageId)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MessageReminderDTO.createdAt, ascending: false)]
        return request
    }
    
    /// Returns a fetch request for message reminders based on the provided query.
    static func remindersFetchRequest(query: MessageReminderListQuery) -> NSFetchRequest<MessageReminderDTO> {
        let request = NSFetchRequest<MessageReminderDTO>(entityName: MessageReminderDTO.entityName)
        MessageReminderDTO.applyPrefetchingState(to: request)
        
        // Apply sort descriptors from the query
        var sortDescriptors: [NSSortDescriptor] = []
        for sorting in query.sort {
            switch sorting.key {
            case .remindAt:
                sortDescriptors.append(NSSortDescriptor(keyPath: \MessageReminderDTO.sortingRemindAt, ascending: sorting.isAscending))
            case .createdAt:
                sortDescriptors.append(NSSortDescriptor(keyPath: \MessageReminderDTO.createdAt, ascending: sorting.isAscending))
            case .updatedAt:
                sortDescriptors.append(NSSortDescriptor(keyPath: \MessageReminderDTO.updatedAt, ascending: sorting.isAscending))
            default:
                continue
            }
        }
        // Apply default sort if none provided
        if sortDescriptors.isEmpty {
            sortDescriptors = [NSSortDescriptor(keyPath: \MessageReminderDTO.sortingRemindAt, ascending: true)]
        }
        request.sortDescriptors = sortDescriptors

        if let filter = query.filter, let predicate = filter.predicate {
            request.predicate = predicate
        }

        return request
    }
    
    /// Loads a reminder with the specified message ID from the context.
    static func load(messageId: MessageId, context: NSManagedObjectContext) -> MessageReminderDTO? {
        let request = fetchRequest(messageId: messageId)
        return load(by: request, context: context).first
    }
    
    /// Loads or creates a reminder with the specified message ID.
    static func loadOrCreate(
        messageId: MessageId,
        context: NSManagedObjectContext,
        cache: PreWarmedCache?
    ) -> MessageReminderDTO {
        // Try to reuse existing object if available
        if let existing = load(messageId: messageId, context: context) {
            return existing
        }
        
        let request = fetchRequest(messageId: messageId)
        let new = NSEntityDescription.insertNewObject(into: context, for: request)
        return new
    }
    
    /// Loads a message reminder DTO with the specified id.
    /// - Parameters:
    ///   - id: The reminder id to look for.
    ///   - context: NSManagedObjectContext to fetch from.
    /// - Returns: The message reminder DTO with the specified id, if exists.
    static func load(id: String, context: NSManagedObjectContext) -> MessageReminderDTO? {
        let request = NSFetchRequest<MessageReminderDTO>(entityName: MessageReminderDTO.entityName)
        request.predicate = NSPredicate(format: "id == %@", id)
        return try? context.fetch(request).first
    }
}

extension NSManagedObjectContext: ReminderDatabaseSession {
    /// Creates or updates a reminder for a message.
    func saveReminder(
        payload: ReminderPayload,
        cache: PreWarmedCache?
    ) throws -> MessageReminderDTO {
        let messageDTO: MessageDTO
        if let existingMessage = MessageDTO.load(id: payload.messageId, context: self) {
            messageDTO = existingMessage
        } else if let messagePayload = payload.message {
            messageDTO = try saveMessage(payload: messagePayload, for: payload.channelCid, cache: cache)
        } else {
            throw ClientError.MessageDoesNotExist(messageId: payload.messageId)
        }

        let channelDTO: ChannelDTO
        if let existingChannel = ChannelDTO.load(cid: payload.channelCid, context: self) {
            channelDTO = existingChannel
        } else if let channelPayload = payload.channel {
            channelDTO = try saveChannel(payload: channelPayload, query: nil, cache: nil)
        } else {
            throw ClientError.ChannelDoesNotExist(cid: payload.channelCid)
        }

        let reminderDTO = MessageReminderDTO.loadOrCreate(
            messageId: payload.messageId,
            context: self,
            cache: cache
        )

        reminderDTO.id = payload.messageId
        reminderDTO.remindAt = payload.remindAt?.bridgeDate
        reminderDTO.createdAt = payload.createdAt.bridgeDate
        reminderDTO.updatedAt = payload.updatedAt.bridgeDate
        reminderDTO.message = messageDTO
        reminderDTO.channel = channelDTO
        
        return reminderDTO
    }
    
    /// Deletes a reminder for the specified message ID.
    func deleteReminder(messageId: MessageId) {
        let message = message(id: messageId)
        guard let reminderDTO = message?.reminder else {
            return
        }
        delete(reminderDTO)
        message?.reminder = nil
    }
}

// MARK: - Converting to domain model

extension MessageReminderDTO {
    /// Snapshots the current state of `MessageReminderDTO` and returns an immutable model object from it.
    /// - Returns: A `MessageReminder` instance created from the DTO data.
    /// - Throws: An error when the underlying data is inconsistent.
    func asModel() throws -> MessageReminder {
        MessageReminder(
            id: id,
            remindAt: remindAt?.bridgeDate,
            message: try message.asModel(),
            channel: try channel.asModel(),
            createdAt: createdAt.bridgeDate,
            updatedAt: updatedAt.bridgeDate
        )
    }
}

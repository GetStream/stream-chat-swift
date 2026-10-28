//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

@objc(ChannelConfigDTO)
final class ChannelConfigDTO: NSManagedObject {
    @NSManaged var reactionsEnabled: Bool
    @NSManaged var typingEventsEnabled: Bool
    @NSManaged var readEventsEnabled: Bool
    @NSManaged var deliveryEventsEnabled: Bool
    @NSManaged var connectEventsEnabled: Bool
    @NSManaged var skipLastMsgAtUpdateForSystemMsg: Bool
    @NSManaged var uploadsEnabled: Bool
    @NSManaged var repliesEnabled: Bool
    @NSManaged var quotesEnabled: Bool
    @NSManaged var searchEnabled: Bool
    @NSManaged var mutesEnabled: Bool
    @NSManaged var pollsEnabled: Bool
    @NSManaged var urlEnrichmentEnabled: Bool
    @NSManaged var messageRetention: String
    @NSManaged var messageRemindersEnabled: Bool
    @NSManaged var maxMessageLength: Int32
    @NSManaged var createdAt: DBDate
    @NSManaged var updatedAt: DBDate
    @NSManaged var commands: NSOrderedSet
    @NSManaged var sharedLocationsEnabled: Bool
    @NSManaged var scheduledMessagesMaxPerChannel: NSNumber?
    @NSManaged var scheduledMessagesMaxPerUser: NSNumber?
    @NSManaged var scheduledMessagesMaxLeadTime: NSNumber?
    @NSManaged var scheduledMessagesMinLeadTime: NSNumber?

    func asModel() throws -> ChannelConfig {
        try isNotDeleted()
        return .init(
            reactionsEnabled: reactionsEnabled,
            typingEventsEnabled: typingEventsEnabled,
            readEventsEnabled: readEventsEnabled,
            deliveryEventsEnabled: deliveryEventsEnabled,
            connectEventsEnabled: connectEventsEnabled,
            uploadsEnabled: uploadsEnabled,
            repliesEnabled: repliesEnabled,
            quotesEnabled: quotesEnabled,
            searchEnabled: searchEnabled,
            mutesEnabled: mutesEnabled,
            pollsEnabled: pollsEnabled,
            urlEnrichmentEnabled: urlEnrichmentEnabled,
            skipLastMsgAtUpdateForSystemMsg: skipLastMsgAtUpdateForSystemMsg,
            messageRemindersEnabled: messageRemindersEnabled,
            sharedLocationsEnabled: sharedLocationsEnabled,
            scheduledMessagesMaxPerChannel: scheduledMessagesMaxPerChannel?.intValue,
            scheduledMessagesMaxPerUser: scheduledMessagesMaxPerUser?.intValue,
            scheduledMessagesMaxLeadTime: scheduledMessagesMaxLeadTime?.doubleValue,
            scheduledMessagesMinLeadTime: scheduledMessagesMinLeadTime?.doubleValue,
            messageRetention: messageRetention,
            maxMessageLength: Int(maxMessageLength),
            commands: Array(Set(
                commands.compactMap { try? ($0 as? CommandDTO)?.asModel() }
            )),
            createdAt: createdAt.bridgeDate,
            updatedAt: updatedAt.bridgeDate
        )
    }
}

extension ChannelConfig {
    func asDTO(context: NSManagedObjectContext, cid: String) -> ChannelConfigDTO {
        let request = NSFetchRequest<ChannelConfigDTO>(entityName: ChannelConfigDTO.entityName)
        request.predicate = NSPredicate(format: "channel.cid == %@", cid)

        let dto: ChannelConfigDTO
        if let loadedDto = ChannelConfigDTO.load(by: request, context: context).first {
            dto = loadedDto
        } else {
            dto = NSEntityDescription.insertNewObject(into: context, for: request)
        }

        dto.reactionsEnabled = reactionsEnabled
        dto.typingEventsEnabled = typingEventsEnabled
        dto.readEventsEnabled = readEventsEnabled
        dto.deliveryEventsEnabled = deliveryEventsEnabled
        dto.connectEventsEnabled = connectEventsEnabled
        dto.uploadsEnabled = uploadsEnabled
        dto.repliesEnabled = repliesEnabled
        dto.quotesEnabled = quotesEnabled
        dto.searchEnabled = searchEnabled
        dto.mutesEnabled = mutesEnabled
        dto.urlEnrichmentEnabled = urlEnrichmentEnabled
        dto.messageRetention = messageRetention
        dto.maxMessageLength = Int32(maxMessageLength)
        dto.createdAt = createdAt.bridgeDate
        dto.updatedAt = updatedAt.bridgeDate
        dto.commands = NSOrderedSet(array: commands.map { $0.asDTO(context: context) })
        dto.pollsEnabled = pollsEnabled
        dto.skipLastMsgAtUpdateForSystemMsg = skipLastMsgAtUpdateForSystemMsg
        dto.messageRemindersEnabled = messageRemindersEnabled
        dto.sharedLocationsEnabled = sharedLocationsEnabled
        dto.scheduledMessagesMaxPerChannel = scheduledMessagesMaxPerChannel.map { NSNumber(value: $0) }
        dto.scheduledMessagesMaxPerUser = scheduledMessagesMaxPerUser.map { NSNumber(value: $0) }
        dto.scheduledMessagesMaxLeadTime = scheduledMessagesMaxLeadTime.map { NSNumber(value: $0) }
        dto.scheduledMessagesMinLeadTime = scheduledMessagesMinLeadTime.map { NSNumber(value: $0) }
        return dto
    }
}

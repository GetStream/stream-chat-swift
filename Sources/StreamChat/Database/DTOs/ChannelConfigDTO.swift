//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

// TODO: expand the db object with missing properties.
@objc(ChannelConfigDTO)
final class ChannelConfigDTO: NSManagedObject {
    @NSManaged var reactionsEnabled: Bool
    @NSManaged var typingEventsEnabled: Bool
    @NSManaged var readEventsEnabled: Bool
    @NSManaged var connectEventsEnabled: Bool
    @NSManaged var uploadsEnabled: Bool
    @NSManaged var repliesEnabled: Bool
    @NSManaged var quotesEnabled: Bool
    @NSManaged var searchEnabled: Bool
    @NSManaged var mutesEnabled: Bool
    @NSManaged var urlEnrichmentEnabled: Bool
    @NSManaged var messageRetention: String
    @NSManaged var maxMessageLength: Int32
    @NSManaged var createdAt: DBDate
    @NSManaged var updatedAt: DBDate
    @NSManaged var commands: NSOrderedSet

    func asModel() throws -> StreamChatChannelConfig {
        guard isValid else { throw InvalidModel(self) }
        return .init(
            connectEvents: connectEventsEnabled,
            createdAt: createdAt.bridgeDate,
            maxMessageLength: Int(maxMessageLength),
            messageRetention: messageRetention,
            mutes: mutesEnabled,
            quotes: quotesEnabled,
            reactions: reactionsEnabled,
            readEvents: readEventsEnabled,
            replies: repliesEnabled,
            search: searchEnabled,
            typingEvents: typingEventsEnabled,
            updatedAt: updatedAt.bridgeDate,
            uploads: uploadsEnabled,
            urlEnrichment: urlEnrichmentEnabled,
            commands: Array(Set(
                commands.compactMap { ($0 as? CommandDTO)?.name }
            ))
        )
    }
}

extension StreamChatChannelConfig {
    func asDTO(context: NSManagedObjectContext, cid: String) -> ChannelConfigDTO {
        let request = NSFetchRequest<ChannelConfigDTO>(entityName: ChannelConfigDTO.entityName)
        request.predicate = NSPredicate(format: "channel.cid == %@", cid)

        let dto: ChannelConfigDTO
        if let loadedDto = ChannelConfigDTO.load(by: request, context: context).first {
            dto = loadedDto
        } else {
            dto = NSEntityDescription.insertNewObject(into: context, for: request)
        }

        dto.reactionsEnabled = reactions
        dto.typingEventsEnabled = typingEvents
        dto.readEventsEnabled = readEvents
        dto.connectEventsEnabled = connectEvents
        dto.uploadsEnabled = uploads
        dto.repliesEnabled = replies
        dto.quotesEnabled = quotes
        dto.searchEnabled = search
        dto.mutesEnabled = mutes
        dto.urlEnrichmentEnabled = urlEnrichment
        dto.messageRetention = messageRetention
        dto.maxMessageLength = Int32(maxMessageLength)
        dto.createdAt = createdAt.bridgeDate
        dto.updatedAt = updatedAt.bridgeDate
        // TODO: check commands.
//        dto.commands = NSOrderedSet(array: commands.map { $0.asDTO(context: context) })
        return dto
    }
}

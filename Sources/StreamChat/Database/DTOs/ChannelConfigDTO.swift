//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

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
    @NSManaged var createdAt: Date
    @NSManaged var updatedAt: Date
    @NSManaged var commands: NSOrderedSet

    func asModel() throws -> ChannelConfig {
        guard isValid else { throw InvalidModel(self) }
        return .init(
            reactionsEnabled: reactionsEnabled,
            typingEventsEnabled: typingEventsEnabled,
            readEventsEnabled: readEventsEnabled,
            connectEventsEnabled: connectEventsEnabled,
            uploadsEnabled: uploadsEnabled,
            repliesEnabled: repliesEnabled,
            quotesEnabled: quotesEnabled,
            searchEnabled: searchEnabled,
            mutesEnabled: mutesEnabled,
            urlEnrichmentEnabled: urlEnrichmentEnabled,
            messageRetention: messageRetention,
            maxMessageLength: Int(maxMessageLength),
            commands: Array(Set(
                commands.compactMap { try? ($0 as? CommandDTO)?.asModel() }
            )),
            createdAt: createdAt,
            updatedAt: updatedAt
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
        dto.connectEventsEnabled = connectEventsEnabled
        dto.uploadsEnabled = uploadsEnabled
        dto.repliesEnabled = repliesEnabled
        dto.quotesEnabled = quotesEnabled
        dto.searchEnabled = searchEnabled
        dto.mutesEnabled = mutesEnabled
        dto.urlEnrichmentEnabled = urlEnrichmentEnabled
        dto.messageRetention = messageRetention
        dto.maxMessageLength = Int32(maxMessageLength)
        dto.createdAt = createdAt
        dto.updatedAt = updatedAt
        dto.commands = NSOrderedSet(array: commands.map { $0.asDTO(context: context) })
        return dto
    }
}

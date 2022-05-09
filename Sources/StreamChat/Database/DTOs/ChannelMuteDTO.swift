//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

@objc(ChannelMuteDTO)
final class ChannelMuteDTO: NSManagedObject {
    @NSManaged var createdAt: Date
    @NSManaged var updatedAt: Date
    @NSManaged var channel: ChannelDTO
    @NSManaged var currentUser: CurrentUserDTO
    
    static func fetchRequest(for cid: ChannelId) -> NSFetchRequest<ChannelMuteDTO> {
        let request = NSFetchRequest<ChannelMuteDTO>(entityName: ChannelMuteDTO.entityName)
        request.predicate = NSPredicate(format: "channel.cid == %@", cid.rawValue)
        return request
    }
    
    static func load(cid: ChannelId, context: NSManagedObjectContext) -> ChannelMuteDTO? {
        load(by: fetchRequest(for: cid), context: context).first
    }
}

extension NSManagedObjectContext {
    @discardableResult
    func saveChannelMute(payload: MutedChannelPayload) throws -> ChannelMuteDTO {
        guard let currentUser = currentUser else {
            throw ClientError.CurrentUserDoesNotExist()
        }
        
        let channel = try saveChannel(payload: payload.mutedChannel, query: nil)
        
        let dto: ChannelMuteDTO
        if let existing = ChannelMuteDTO.load(cid: payload.mutedChannel.cid, context: self) {
            dto = existing
        } else {
            dto = NSEntityDescription.insertNewObject(forEntityName: ChannelMuteDTO.entityName, into: self) as! ChannelMuteDTO
        }
        dto.channel = channel
        dto.currentUser = currentUser
        dto.createdAt = payload.createdAt
        dto.updatedAt = payload.updatedAt

        return dto
    }
}

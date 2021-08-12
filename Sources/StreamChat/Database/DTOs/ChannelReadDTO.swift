//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

@objc(ChannelReadDTO)
class ChannelReadDTO: NSManagedObject {
    @NSManaged var lastReadAt: Date
    @NSManaged var unreadMessageCount: Int32
    
    // MARK: - Relationships
    
    @NSManaged var channel: ChannelDTO
    @NSManaged var user: UserDTO
    
    override func willSave() {
        super.willSave()
        
        // When the read is updated, we need to propagate this change up to holding channel
        if hasPersistentChangedValues, !channel.hasChanges {
            // this will not change object, but mark it as dirty, triggering updates
            channel.cid = channel.cid
        }
    }
    
    static func fetchRequest(userId: String) -> NSFetchRequest<ChannelReadDTO> {
        let request = NSFetchRequest<ChannelReadDTO>(entityName: ChannelReadDTO.entityName)
        request.predicate = NSPredicate(format: "user.id == %@", userId)
        return request
    }
    
    static func fetchRequest(for cid: ChannelId, userId: String) -> NSFetchRequest<ChannelReadDTO> {
        let request = NSFetchRequest<ChannelReadDTO>(entityName: ChannelReadDTO.entityName)
        request.predicate = NSPredicate(format: "channel.cid == %@ && user.id == %@", cid.rawValue, userId)
        return request
    }
    
    static func load(userId: String, context: NSManagedObjectContext) -> [ChannelReadDTO] {
        load(by: fetchRequest(userId: userId), context: context)
    }
    
    static func load(cid: ChannelId, userId: String, context: NSManagedObjectContext) -> ChannelReadDTO? {
        load(by: fetchRequest(for: cid, userId: userId), context: context).first
    }
    
    static func loadOrCreate(cid: ChannelId, userId: String, context: NSManagedObjectContext) -> ChannelReadDTO {
        if let existing = Self.load(cid: cid, userId: userId, context: context) {
            return existing
        }
        
        let new = NSEntityDescription.insertNewObject(forEntityName: Self.entityName, into: context) as! ChannelReadDTO
        new.channel = ChannelDTO.loadOrCreate(cid: cid, context: context)
        new.user = UserDTO.loadOrCreate(id: userId, context: context)
        return new
    }
    
    /// Snapshots the current state of `ChannelReadDTO` and returns an immutable model object from it.
    func asModel() -> ChatChannelRead { .create(fromDTO: self) }
}

// MARK: Saving and loading the data

extension NSManagedObjectContext {
    func saveChannelRead(
        cid: ChannelId,
        userId: UserId,
        lastReadAt: Date,
        unreadMessageCount: Int
    ) -> ChannelReadDTO {
        let dto = ChannelReadDTO.loadOrCreate(cid: cid, userId: userId, context: self)
        
        dto.user = UserDTO.loadOrCreate(id: userId, context: self)
        
        dto.lastReadAt = lastReadAt
        dto.unreadMessageCount = Int32(unreadMessageCount)
        
        return dto
    }
    
    func saveChannelRead(
        payload: ChannelReadPayload,
        for cid: ChannelId
    ) throws -> ChannelReadDTO {
        let dto = ChannelReadDTO.loadOrCreate(cid: cid, userId: payload.user.id, context: self)
        
        dto.user = try saveUser(payload: payload.user)
        
        dto.lastReadAt = payload.lastReadAt
        dto.unreadMessageCount = Int32(payload.unreadMessagesCount)
        
        return dto
    }
    
    func loadChannelRead(cid: ChannelId, userId: String) -> ChannelReadDTO? {
        ChannelReadDTO.load(cid: cid, userId: userId, context: self)
    }
    
    func loadChannelReads(for userId: UserId) -> [ChannelReadDTO] {
        ChannelReadDTO.load(userId: userId, context: self)
    }
}

extension ChatChannelRead {
    fileprivate static func create(fromDTO dto: ChannelReadDTO) -> ChatChannelRead {
        .init(lastReadAt: dto.lastReadAt, unreadMessagesCount: Int(dto.unreadMessageCount), user: dto.user.asModel())
    }
}

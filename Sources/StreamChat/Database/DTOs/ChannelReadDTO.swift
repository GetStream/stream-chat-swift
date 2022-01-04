//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

@objc(ChannelReadDTO)
class ChannelReadDTO: NSManagedObject {
    @NSManaged var lastReadAt: Date?
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
    
    func markChannelAsRead(cid: ChannelId, userId: UserId, at: Date) {
        if let read = loadChannelRead(cid: cid, userId: userId) {
            // We have a read object saved, we can update it
            read.lastReadAt = at
            read.unreadMessageCount = 0
        } else if let channel = channel(cid: cid), channel.members.contains(where: { $0.user.id == userId }) {
            // We don't have a read object, but the user is a member.
            // We can safely create a read object for the user
            _ = saveChannelRead(cid: cid, userId: userId, lastReadAt: at, unreadMessageCount: 0)
        } else {
            // If we don't have a read object saved for the user,
            // and the user is not a member,
            // we can safely discard this event.
            log.debug(
                "Discarding read event for cid \(cid) and userId \(userId). "
                    + "This is expected when the user calls `markRead` but they're not a member."
            )
        }
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
        .init(
            lastReadAt: dto.lastReadAt ?? Date.distantPast,
            unreadMessagesCount: Int(dto.unreadMessageCount),
            user: dto.user.asModel()
        )
    }
}

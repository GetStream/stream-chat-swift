//
// Copyright © 2022 Stream.io Inc. All rights reserved.
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
        let request = fetchRequest(for: cid, userId: userId)
        if let existing = load(by: request, context: context).first {
            return existing
        }
        
        let new = NSEntityDescription.insertNewObject(into: context, for: request)
        return new
    }
    
    /// Snapshots the current state of `ChannelReadDTO` and returns an immutable model object from it.
    func asModel() throws -> ChatChannelRead { try .create(fromDTO: self) }
}

// MARK: Saving and loading the data

extension NSManagedObjectContext {
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
            let previousLastReadAt = read.lastReadAt
            
            // We have a read object saved, we can update it
            read.lastReadAt = at
            read.unreadMessageCount = 0
            
            // Mark messages authored by the current user sent within `previousLastReadAt...at` window
            // as seen by the channel member with `userId`.
            markMessagesFromCurrentUserAsRead(
                for: read,
                previousReadAt: previousLastReadAt
            )
        } else if let channel = channel(cid: cid), let member = channel.members.first(where: { $0.user.id == userId }) {
            // We don't have a read object, but the user is a member.
            // We can safely create a read object for the user
            let read = ChannelReadDTO.loadOrCreate(cid: cid, userId: userId, context: self)
            read.channel = channel
            read.user = member.user
            read.lastReadAt = at
            read.unreadMessageCount = 0
            
            // Mark all locally existed messages authored by the current user
            // as seen by the channel member with `userId`.
            markMessagesFromCurrentUserAsRead(
                for: read,
                previousReadAt: .distantPast
            )
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
    
    func markChannelAsUnread(cid: ChannelId, by userId: UserId) {
        guard let read = loadChannelRead(cid: cid, userId: userId) else { return }
                
        delete(read)
    }

    func loadChannelRead(cid: ChannelId, userId: String) -> ChannelReadDTO? {
        ChannelReadDTO.load(cid: cid, userId: userId, context: self)
    }
    
    func loadChannelReads(for userId: UserId) -> [ChannelReadDTO] {
        ChannelReadDTO.load(userId: userId, context: self)
    }
    
    private func markMessagesFromCurrentUserAsRead(
        for read: ChannelReadDTO,
        previousReadAt: Date
    ) {
        guard read.user.currentUser == nil else {
            // Current user is not accounted in his own message reads.
            return
        }
        
        let messages = MessageDTO.loadCurrentUserMessages(
            in: read.channel.cid,
            createdAtFrom: previousReadAt,
            createdAtThrough: read.lastReadAt,
            context: self
        )
        
        for message in messages {
            message.reads.insert(read)
        }
    }
}

extension ChatChannelRead {
    fileprivate static func create(fromDTO dto: ChannelReadDTO) throws -> ChatChannelRead {
        guard dto.isValid else { throw InvalidModel(dto) }
        return try .init(
            lastReadAt: dto.lastReadAt,
            unreadMessagesCount: Int(dto.unreadMessageCount),
            user: dto.user.asModel()
        )
    }
}

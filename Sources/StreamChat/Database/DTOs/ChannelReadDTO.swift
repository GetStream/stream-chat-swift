//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

@objc(ChannelReadDTO)
class ChannelReadDTO: NSManagedObject {
    @NSManaged var lastReadAt: Date
    @NSManaged var unreadMessageCount: Int32
    @NSManaged var unreadSilentMessagesCount: Int32
    @NSManaged var unreadThreadRepliesCount: Int32

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
        payload: ChannelReadPayload,
        for cid: ChannelId
    ) throws -> ChannelReadDTO {
        let dto = ChannelReadDTO.loadOrCreate(cid: cid, userId: payload.user.id, context: self)
        
        dto.user = try saveUser(payload: payload.user)
        
        dto.lastReadAt = payload.lastReadAt
        dto.unreadMessageCount = Int32(payload.unreadMessagesCount)
        dto.unreadSilentMessagesCount = dto.user.currentUser == nil ? 0 : dto.unreadSilentMessagesCount
        dto.unreadThreadRepliesCount = dto.user.currentUser == nil ? 0 : dto.unreadThreadRepliesCount
        
        return dto
    }
    
    func markChannelAsRead(cid: ChannelId, userId: UserId, at: Date) {
        let channelRead: ChannelReadDTO
        let previouslyReadAt: Date

        if let read = loadChannelRead(cid: cid, userId: userId) {
            previouslyReadAt = read.lastReadAt
            channelRead = read
        } else if let channel = channel(cid: cid), let member = channel.members.first(where: { $0.user.id == userId }) {
            previouslyReadAt = .distantPast

            // We don't have a read object, but the user is a member.
            // We can safely create a read object for the user
            channelRead = ChannelReadDTO.loadOrCreate(cid: cid, userId: userId, context: self)
            channelRead.channel = channel
            channelRead.user = member.user
        } else {
            // If we don't have a read object saved for the user,
            // and the user is not a member,
            // we can safely discard this event.
            log.debug(
                "Discarding read event for cid \(cid) and userId \(userId). "
                    + "This is expected when the user calls `markRead` but they're not a member."
            )
            return
        }
        
        // Update channel read
        channelRead.lastReadAt = at
        channelRead.unreadMessageCount = 0
        channelRead.unreadSilentMessagesCount = 0
        channelRead.unreadThreadRepliesCount = 0
        
        // Mark all locally existed messages authored by the current user
        // as seen by the channel member with `userId`.
        markMessagesFromCurrentUserAsRead(
            for: channelRead,
            previousReadAt: previouslyReadAt
        )
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
    fileprivate static func create(fromDTO dto: ChannelReadDTO) -> ChatChannelRead {
        .init(
            lastReadAt: dto.lastReadAt,
            unreadMessagesCount: Int(dto.unreadMessageCount),
            user: dto.user.asModel()
        )
    }
}

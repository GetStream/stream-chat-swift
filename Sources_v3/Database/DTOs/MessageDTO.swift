//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

@objc(MessageDTO)
class MessageDTO: NSManagedObject {
    static let entityName = "MessageDTO"
    
    @NSManaged var additionalStateRaw: Int16
    @NSManaged var id: String
    @NSManaged var text: String
    @NSManaged var type: String
    @NSManaged var command: String?
    @NSManaged var createdAt: Date
    @NSManaged var updatedAt: Date
    @NSManaged var deletedAt: Date?
    @NSManaged var args: String?
    @NSManaged var parentMessageId: MessageId?
    @NSManaged var showReplyInChannel: Bool
    @NSManaged var replyCount: Int32
    @NSManaged var extraData: Data
    @NSManaged var isSilent: Bool
    @NSManaged var reactionScores: [String: Int]
    
    @NSManaged var user: UserDTO
    @NSManaged var mentionedUsers: Set<UserDTO>
    @NSManaged var channel: ChannelDTO
    
    /// Returns a fetch request for messages from the channel with the provided `cid`.
    static func messagesFetchRequest(for cid: ChannelId) -> NSFetchRequest<MessageDTO> {
        let request = NSFetchRequest<MessageDTO>(entityName: MessageDTO.entityName)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MessageDTO.createdAt, ascending: false)]
        request.predicate = NSPredicate(format: "channel.cid == %@", cid.rawValue)
        return request
    }
    
    static func load(for cid: String, limit: Int, offset: Int = 0, context: NSManagedObjectContext) -> [MessageDTO] {
        let request = NSFetchRequest<MessageDTO>(entityName: entityName)
        request.predicate = NSPredicate(format: "channel.cid == %@", cid)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MessageDTO.createdAt, ascending: false)]
        request.fetchLimit = limit
        request.fetchOffset = offset
        return try! context.fetch(request)
    }
    
    static func load(id: String, context: NSManagedObjectContext) -> MessageDTO? {
        let request = NSFetchRequest<MessageDTO>(entityName: entityName)
        request.predicate = NSPredicate(format: "id == %@", id)
        return try! context.fetch(request).first
    }
    
    static func loadOrCreate(id: String, context: NSManagedObjectContext) -> MessageDTO {
        if let existing = load(id: id, context: context) {
            return existing
        }
        
        let new = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context) as! Self
        new.id = id
        return new
    }
}

extension NSManagedObjectContext: MessageDatabaseSession {
    func saveMessage<ExtraData: ExtraDataTypes>(payload: MessagePayload<ExtraData>, for cid: ChannelId) throws -> MessageDTO {
        let dto = MessageDTO.loadOrCreate(id: payload.id, context: self)
        
        dto.text = payload.text
        dto.createdAt = payload.createdAt
        dto.updatedAt = payload.updatedAt
        dto.deletedAt = payload.deletedAt
        dto.type = payload.type.rawValue
        dto.command = payload.command
        dto.args = payload.args
        dto.parentMessageId = payload.parentId
        dto.showReplyInChannel = payload.showReplyInChannel
        dto.replyCount = Int32(payload.replyCount)
        dto.extraData = try JSONEncoder.default.encode(payload.extraData)
        dto.isSilent = payload.isSilent
        dto.reactionScores = payload.reactionScores
        dto.channel = ChannelDTO.loadOrCreate(cid: cid, context: self)
        
        let user = try saveUser(payload: payload.user)
        dto.user = user
        
        try payload.mentionedUsers.forEach { userPayload in
            let user = try saveUser(payload: userPayload)
            dto.mentionedUsers.insert(user)
        }
        
        return dto
    }
    
    func message(id: MessageId) -> MessageDTO? { .load(id: id, context: self) }
}

extension MessageDTO {
    /// Snapshots the current state of `MessageDTO` and returns an immutable model object from it.
    func asModel<ExtraData: ExtraDataTypes>() -> MessageModel<ExtraData> { .init(fromDTO: self) }
    
    /// Snapshots the current state of `MessageDTO` and returns its representation for the use in API calls.
    func asRequestBody<ExtraData: ExtraDataTypes>() -> MessageRequestBody<ExtraData> {
        var extraData: ExtraData.Message?
        do {
            extraData = try JSONDecoder.default.decode(ExtraData.Message.self, from: self.extraData)
        } catch {
            log.assert(false, "Failed decoding saved extra data with error: \(error). This should never happen because"
                + "the extra data must be a valid JSON to be saved.")
        }
        
        return .init(id: id,
                     user: user.asRequestBody(),
                     text: text,
                     command: command,
                     args: args,
                     parentId: parentMessageId,
                     showReplyInChannel: showReplyInChannel,
                     extraData: extraData ?? .defaultValue)
    }
}

extension MessageModel {
    fileprivate init(fromDTO dto: MessageDTO) {
        id = dto.id
        text = dto.text
        type = MessageType(rawValue: dto.type) ?? .regular
        command = dto.command
        createdAt = dto.createdAt
        updatedAt = dto.updatedAt
        deletedAt = dto.deletedAt
        arguments = dto.args
        parentMessageId = dto.parentMessageId
        showReplyInChannel = dto.showReplyInChannel
        replyCount = Int(dto.replyCount)
        extraData = try! JSONDecoder.default.decode(ExtraData.Message.self, from: dto.extraData)
        isSilent = dto.isSilent
        reactionScores = dto.reactionScores
        
        author = dto.user.asModel()
        mentionedUsers = Set(dto.mentionedUsers.map { $0.asModel() })
    }
}

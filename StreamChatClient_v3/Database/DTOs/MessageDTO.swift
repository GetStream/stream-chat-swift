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
    @NSManaged var createdDate: Date
    @NSManaged var updatedDate: Date
    @NSManaged var deletedDate: Date?
    @NSManaged var args: String?
    @NSManaged var parentId: String?
    @NSManaged var showReplyInChannel: Bool
    @NSManaged var replyCount: Int32
    @NSManaged var extraData: Data
    @NSManaged var isSilent: Bool
    @NSManaged var reactionScores: [String: Int]
    
    @NSManaged var user: UserDTO
    @NSManaged var mentionedUsers: Set<UserDTO>
    @NSManaged var channel: ChannelDTO
    
    static func load(for cid: String, limit: Int, offset: Int = 0, context: NSManagedObjectContext) -> [MessageDTO] {
        let request = NSFetchRequest<MessageDTO>(entityName: entityName)
        request.predicate = NSPredicate(format: "channel.cid == %@", cid)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MessageDTO.createdDate, ascending: false)]
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

extension NSManagedObjectContext {
    func saveMessage<ExtraData: ExtraDataTypes>(payload: MessagePayload<ExtraData>, for cid: ChannelId) throws -> MessageDTO {
        let dto = MessageDTO.loadOrCreate(id: payload.id, context: self)
        
        dto.text = payload.text
        dto.createdDate = payload.created
        dto.updatedDate = payload.updated
        dto.deletedDate = payload.deleted
        dto.type = payload.type.rawValue
        dto.command = payload.command
        dto.args = payload.args
        dto.parentId = payload.parentId
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
}

extension MessageModel {
    init(fromDTO dto: MessageDTO) {
        id = dto.id
        text = dto.text
        type = MessageType(rawValue: dto.type) ?? .regular
        command = dto.command
        createdDate = dto.createdDate
        updatedDate = dto.updatedDate
        deletedDate = dto.deletedDate
        args = dto.args
        parentId = dto.parentId
        showReplyInChannel = dto.showReplyInChannel
        replyCount = dto.replyCount
        extraData = try! JSONDecoder.default.decode(ExtraData.Message.self, from: dto.extraData)
        isSilent = dto.isSilent
        reactionScores = dto.reactionScores
        
        author = UserModel.create(fromDTO: dto.user)
        mentionedUsers = Set(dto.mentionedUsers.map(UserModel<ExtraData.User>.create(fromDTO:)))
    }
}

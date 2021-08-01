//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

@objc(MessageReactionDTO)
final class MessageReactionDTO: NSManagedObject {
    @NSManaged fileprivate var id: String
    
    @NSManaged var type: String
    @NSManaged var score: Int64
    @NSManaged var createdAt: Date
    @NSManaged var updatedAt: Date
    @NSManaged var extraData: Data
    
    @NSManaged var message: MessageDTO
    @NSManaged var user: UserDTO
    
    private static func createId(
        userId: String,
        messageId: MessageId,
        type: MessageReactionType
    ) -> String {
        [userId, messageId, type.rawValue].joined(separator: "/")
    }
}

extension MessageReactionDTO {
    static func load(
        userId: String,
        messageId: MessageId,
        type: MessageReactionType,
        context: NSManagedObjectContext
    ) -> MessageReactionDTO? {
        let id = createId(userId: userId, messageId: messageId, type: type)
        let request = NSFetchRequest<MessageReactionDTO>(entityName: MessageReactionDTO.entityName)
        request.predicate = NSPredicate(format: "id == %@", id)
        return try? context.fetch(request).first
    }
    
    static func loadReactions(
        for messageId: MessageId,
        authoredBy userId: UserId,
        context: NSManagedObjectContext
    ) -> [MessageReactionDTO] {
        let request = NSFetchRequest<MessageReactionDTO>(entityName: MessageReactionDTO.entityName)
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "message.id == %@", messageId),
            NSPredicate(format: "user.id == %@", userId)
        ])
        
        return (try? context.fetch(request)) ?? []
    }
    
    static func loadLatestReactions(
        for messageId: MessageId,
        limit: Int,
        context: NSManagedObjectContext
    ) -> [MessageReactionDTO] {
        let request = NSFetchRequest<MessageReactionDTO>(entityName: MessageReactionDTO.entityName)
        request.predicate = NSPredicate(format: "message.id == %@", messageId)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MessageReactionDTO.updatedAt, ascending: false)]
        request.fetchLimit = limit
        
        return (try? context.fetch(request)) ?? []
    }
    
    static func loadOrCreate(
        userId: String,
        messageId: MessageId,
        type: MessageReactionType,
        context: NSManagedObjectContext
    ) -> MessageReactionDTO {
        if let existing = Self.load(userId: userId, messageId: messageId, type: type, context: context) {
            return existing
        }
        
        let new = NSEntityDescription.insertNewObject(forEntityName: Self.entityName, into: context) as! MessageReactionDTO
        new.id = createId(userId: userId, messageId: messageId, type: type)
        return new
    }
}

extension NSManagedObjectContext {
    func reaction(messageId: MessageId, userId: UserId, type: MessageReactionType) -> MessageReactionDTO? {
        MessageReactionDTO.load(userId: userId, messageId: messageId, type: type, context: self)
    }
    
    @discardableResult
    func saveReaction(
        payload: MessageReactionPayload
    ) throws -> MessageReactionDTO {
        guard let messageDTO = MessageDTO.load(id: payload.messageId, context: self) else {
            throw ClientError.MessageDoesNotExist(messageId: payload.messageId)
        }
        
        let dto = MessageReactionDTO.loadOrCreate(
            userId: payload.user.id,
            messageId: payload.messageId,
            type: payload.type,
            context: self
        )
        
        dto.type = payload.type.rawValue
        dto.score = Int64(clamping: payload.score)
        dto.createdAt = payload.createdAt
        dto.updatedAt = payload.updatedAt
        dto.extraData = try JSONEncoder.default.encode(payload.extraData)
        dto.user = try saveUser(payload: payload.user)
        dto.message = messageDTO
        
        return dto
    }
    
    func delete(reaction: MessageReactionDTO) {
        delete(reaction)
    }
}

extension MessageReactionDTO {
    /// Snapshots the current state of `MessageReactionDTO` and returns an immutable model object from it.
    func asModel() -> ChatMessageReaction {
        let extraData: CustomData
        do {
            extraData = try JSONDecoder.default.decode(CustomData.self, from: self.extraData)
        } catch {
            log.error("Failed decoding saved extra data with error: \(error)")
            extraData = .defaultValue
        }

        return .init(
            type: .init(rawValue: type),
            score: Int(score),
            createdAt: createdAt,
            updatedAt: updatedAt,
            extraData: extraData,
            author: user.asModel()
        )
    }
}

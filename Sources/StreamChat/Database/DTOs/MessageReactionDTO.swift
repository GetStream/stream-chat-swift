//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

@objc(MessageReactionDTO)
final class MessageReactionDTO: NSManagedObject {
    @NSManaged fileprivate var id: String

    @NSManaged fileprivate var localStateRaw: String?
    @NSManaged var type: String
    @NSManaged var score: Int64
    @NSManaged var createdAt: Date?
    @NSManaged var updatedAt: Date?
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
    
    static func createId(
        dto: MessageReactionDTO
    ) -> String {
        createId(userId: dto.user.id, messageId: dto.message.id, type: .init(rawValue: dto.type))
    }
    
    static func hasChanged(reaction: MessageReactionDTO, score: Int, extraData: [String: RawJSON]) -> Bool {
        if reaction.score != score {
            return true
        }

        // TODO: implement cmp between reaction.extraData and extraData
        return false
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

    static let notLocallyDeletedPredicates: NSPredicate = {
        NSCompoundPredicate(orPredicateWithSubpredicates: [
            NSPredicate(format: "localStateRaw == nil"),
            NSPredicate(format: "localStateRaw == %@", LocalReactionState.sending.rawValue),
            NSPredicate(format: "localStateRaw == %@", LocalReactionState.pendingSend.rawValue)
        ])
    }()

    static func loadReactions(
        for messageId: MessageId,
        authoredBy userId: UserId,
        context: NSManagedObjectContext
    ) -> [MessageReactionDTO] {
        let request = NSFetchRequest<MessageReactionDTO>(entityName: MessageReactionDTO.entityName)
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "message.id == %@", messageId),
            NSPredicate(format: "user.id == %@", userId),
            Self.notLocallyDeletedPredicates
        ])
        
        return (try? context.fetch(request)) ?? []
    }

    static func loadLatestReactions(
        for messageId: MessageId,
        limit: Int,
        context: NSManagedObjectContext
    ) -> [MessageReactionDTO] {
        let request = NSFetchRequest<MessageReactionDTO>(entityName: MessageReactionDTO.entityName)
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "message.id == %@", messageId),
            Self.notLocallyDeletedPredicates
        ])
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MessageReactionDTO.updatedAt, ascending: false)]
        request.fetchLimit = limit
        
        return (try? context.fetch(request)) ?? []
    }
    
    static func loadOrCreate(
        messageId: MessageId,
        type: MessageReactionType,
        user: UserDTO,
        context: NSManagedObjectContext
    ) throws -> (dto: MessageReactionDTO, created: Bool) {
        let userId = user.id

        if let existing = Self.load(userId: userId, messageId: messageId, type: type, context: context) {
            return (existing, false)
        }

        guard let message = MessageDTO.load(id: messageId, context: context) else {
            throw ClientError.MessageDoesNotExist(messageId: messageId)
        }

        let new = NSEntityDescription.insertNewObject(forEntityName: Self.entityName, into: context) as! MessageReactionDTO
        new.id = createId(userId: userId, messageId: messageId, type: type)
        new.type = type.rawValue
        new.message = message
        new.user = user
        return (new, true)
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
        let result = try MessageReactionDTO.loadOrCreate(
            messageId: payload.messageId,
            type: payload.type,
            user: try saveUser(payload: payload.user),
            context: self
        )
        
        let dto = result.dto
        dto.score = Int64(clamping: payload.score)
        dto.createdAt = payload.createdAt
        dto.updatedAt = payload.updatedAt
        dto.extraData = try JSONEncoder.default.encode(payload.extraData)
        return dto
    }
    
    func delete(reaction: MessageReactionDTO) {
        delete(reaction)
    }
}

extension MessageReactionDTO {
    var localState: LocalReactionState? {
        get {
            guard let state = localStateRaw else {
                return nil
            }
            return LocalReactionState(rawValue: state)
        }
        set(state) {
            localStateRaw = state?.rawValue
        }
    }

    /// Snapshots the current state of `MessageReactionDTO` and returns an immutable model object from it.
    func asModel() -> ChatMessageReaction {
        let extraData: [String: RawJSON]

        if self.extraData.isEmpty {
            extraData = [:]
        } else {
            do {
                extraData = try JSONDecoder.default.decode([String: RawJSON].self, from: self.extraData)
            } catch {
                log.error("Failed decoding saved extra data with error: \(error)")
                extraData = [:]
            }
        }

        return .init(
            type: .init(rawValue: type),
            score: Int(score),
            createdAt: createdAt ?? .init(),
            updatedAt: updatedAt ?? .init(),
            extraData: extraData,
            author: user.asModel()
        )
    }
}

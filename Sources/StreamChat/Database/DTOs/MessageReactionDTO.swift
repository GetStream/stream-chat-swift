//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

@objc(MessageReactionDTO)
final class MessageReactionDTO: NSManagedObject {
    @NSManaged private(set) var id: String

    // holds the rawValue of LocalReactionState
    @NSManaged fileprivate var localStateRaw: String?
    @NSManaged var type: String
    @NSManaged var score: Int64
    @NSManaged var createdAt: Date?
    @NSManaged var updatedAt: Date?
    @NSManaged var extraData: Data
    
    @NSManaged var message: MessageDTO
    @NSManaged var user: UserDTO

    // internal field needed to sync data optimistically
    @NSManaged var version: String?

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

    static let notLocallyDeletedPredicates: NSPredicate = {
        NSCompoundPredicate(orPredicateWithSubpredicates: [
            NSPredicate(format: "localStateRaw == nil"),
            NSPredicate(format: "localStateRaw == %@", LocalReactionState.sending.rawValue),
            NSPredicate(format: "localStateRaw == %@", LocalReactionState.pendingSend.rawValue)
        ])
    }()

    static func loadReactions(ids: [String], context: NSManagedObjectContext) -> [MessageReactionDTO] {
        guard !ids.isEmpty else {
            return []
        }

        let request = NSFetchRequest<MessageReactionDTO>(entityName: MessageReactionDTO.entityName)
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "id IN %@", ids),
            Self.notLocallyDeletedPredicates
        ])
        return (try? context.fetch(request)) ?? []
    }
    
    static func loadOrCreate(
        message: MessageDTO,
        type: MessageReactionType,
        user: UserDTO,
        context: NSManagedObjectContext
    ) throws -> MessageReactionDTO {
        let userId = user.id

        if let existing = Self.load(userId: userId, messageId: message.id, type: type, context: context) {
            return existing
        }

        let new = NSEntityDescription.insertNewObject(forEntityName: Self.entityName, into: context) as! MessageReactionDTO
        new.id = createId(userId: userId, messageId: message.id, type: type)
        new.type = type.rawValue
        new.message = message
        new.user = user
        return new
    }

    static func loadOrCreate(
        messageId: MessageId,
        type: MessageReactionType,
        user: UserDTO,
        context: NSManagedObjectContext
    ) throws -> MessageReactionDTO {
        let userId = user.id

        if let existing = Self.load(userId: userId, messageId: messageId, type: type, context: context) {
            return existing
        }

        guard let message = MessageDTO.load(id: messageId, context: context) else {
            throw ClientError.MessageDoesNotExist(messageId: messageId)
        }

        return try loadOrCreate(message: message, type: type, user: user, context: context)
    }
}

extension NSManagedObjectContext {
    func reaction(messageId: MessageId, userId: UserId, type: MessageReactionType) -> MessageReactionDTO? {
        MessageReactionDTO.load(userId: userId, messageId: messageId, type: type, context: self)
    }

    func populateFieldsBeforeSave(dto: MessageReactionDTO, payload: MessageReactionPayload) throws {
        dto.score = Int64(clamping: payload.score)
        dto.createdAt = payload.createdAt
        dto.updatedAt = payload.updatedAt
        dto.extraData = try JSONEncoder.default.encode(payload.extraData)
        dto.localState = nil
        dto.version = nil
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

        try populateFieldsBeforeSave(dto: result, payload: payload)
        
        return result
    }

    @discardableResult
    func saveReaction(
        payload: MessageReactionPayload,
        message: MessageDTO
    ) throws -> MessageReactionDTO {
        let result = try MessageReactionDTO.loadOrCreate(
            message: message,
            type: payload.type,
            user: try saveUser(payload: payload.user),
            context: self
        )

        try populateFieldsBeforeSave(dto: result, payload: payload)
        
        return result
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
            author: user.asModel(),
            extraData: extraData
        )
    }
}

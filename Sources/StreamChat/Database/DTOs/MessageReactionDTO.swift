//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

@objc(MessageReactionDTO)
final class MessageReactionDTO: NSManagedObject {
    @NSManaged private(set) var id: String

    // holds the rawValue of LocalReactionState
    @NSManaged fileprivate var localStateRaw: String
    @NSManaged var type: String
    @NSManaged var score: Int64
    @NSManaged var createdAt: DBDate?
    @NSManaged var updatedAt: DBDate?
    @NSManaged var extraData: Data?

    @NSManaged var message: MessageDTO
    @NSManaged var user: UserDTO

    // internal field needed to sync data optimistically
    @NSManaged var version: String?

    static func createId(
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
        return load(reactionId: id, context: context)
    }

    static func load(reactionId: String, context: NSManagedObjectContext) -> MessageReactionDTO? {
        load(by: reactionId, context: context).first
    }

    static let notLocallyDeletedPredicates: NSPredicate = {
        NSCompoundPredicate(orPredicateWithSubpredicates: [
            NSPredicate(format: "localStateRaw == %@", LocalReactionState.unknown.rawValue),
            NSPredicate(format: "localStateRaw == %@", LocalReactionState.sending.rawValue),
            NSPredicate(format: "localStateRaw == %@", LocalReactionState.pendingSend.rawValue),
            NSPredicate(format: "localStateRaw == %@", LocalReactionState.deletingFailed.rawValue)
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
        return load(by: request, context: context)
    }

    static func loadOrCreate(
        message: MessageDTO,
        type: MessageReactionType,
        user: UserDTO,
        context: NSManagedObjectContext,
        cache: PreWarmedCache?
    ) -> MessageReactionDTO {
        let reactionId = createId(userId: user.id, messageId: message.id, type: type)
        if let cachedObject = cache?.model(for: reactionId, context: context, type: MessageReactionDTO.self) {
            return cachedObject
        }

        if let existing = load(reactionId: reactionId, context: context) {
            return existing
        }

        let request = fetchRequest(id: reactionId)
        let new = NSEntityDescription.insertNewObject(into: context, for: request)
        new.id = reactionId
        new.type = type.rawValue
        new.message = message
        new.user = user
        return new
    }
}

extension NSManagedObjectContext {
    func reaction(messageId: MessageId, userId: UserId, type: MessageReactionType) -> MessageReactionDTO? {
        MessageReactionDTO.load(userId: userId, messageId: messageId, type: type, context: self)
    }

    func delete(reaction: MessageReactionDTO) {
        delete(reaction)
    }
}

extension MessageReactionDTO {
    var localState: LocalReactionState? {
        get {
            LocalReactionState(rawValue: localStateRaw)
        }
        set(state) {
            localStateRaw = state?.rawValue ?? LocalReactionState.unknown.rawValue
        }
    }

    /// Snapshots the current state of `MessageReactionDTO` and returns an immutable model object from it.
    func asModel() throws -> ChatMessageReaction {
        guard isValid else { throw InvalidModel(self) }
        let decodedExtraData: [String: RawJSON]

        if let extraData = self.extraData, !extraData.isEmpty {
            do {
                decodedExtraData = try JSONDecoder.default.decode([String: RawJSON].self, from: extraData)
            } catch {
                log.error("Failed decoding saved extra data with error: \(error)")
                decodedExtraData = [:]
            }
        } else {
            decodedExtraData = [:]
        }

        return try .init(
            type: .init(rawValue: type),
            score: Int(score),
            createdAt: createdAt?.bridgeDate ?? .init(),
            updatedAt: updatedAt?.bridgeDate ?? .init(),
            author: user.asModel(),
            extraData: decodedExtraData
        )
    }
}

//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

@objc(MessageReactionGroupDTO)
final class MessageReactionGroupDTO: NSManagedObject {
    @NSManaged var type: String
    @NSManaged var sumScores: Int64
    @NSManaged var count: Int64
    @NSManaged var firstReactionAt: DBDate
    @NSManaged var lastReactionAt: DBDate

    convenience init(
        type: MessageReactionType,
        payload: MessageReactionGroupPayload,
        context: NSManagedObjectContext
    ) {
        self.init(context: context)
        self.type = type.rawValue
        count = Int64(payload.count)
        sumScores = Int64(payload.sumScores)
        firstReactionAt = payload.firstReactionAt.bridgeDate
        lastReactionAt = payload.lastReactionAt.bridgeDate
    }

    convenience init(
        type: MessageReactionType,
        sumScores: Int,
        count: Int,
        firstReactionAt: Date,
        lastReactionAt: Date,
        context: NSManagedObjectContext
    ) {
        self.init(context: context)
        self.type = type.rawValue
        self.count = Int64(count)
        self.sumScores = Int64(sumScores)
        self.firstReactionAt = firstReactionAt.bridgeDate
        self.lastReactionAt = lastReactionAt.bridgeDate
    }
}

extension Set where Element == MessageReactionGroupDTO {
    subscript(_ type: String) -> MessageReactionGroupDTO? {
        first(where: { $0.type == type })
    }

    func asModel() -> [MessageReactionType: ChatMessageReactionGroup] {
        reduce(into: [:]) { partialResult, groupDTO in
            guard let model = try? groupDTO.asModel() else { return }
            partialResult[MessageReactionType(rawValue: groupDTO.type)] = model
        }
    }
}

extension MessageReactionGroupDTO {
    func asModel() throws -> ChatMessageReactionGroup {
        guard !isDeleted else { throw DeletedModel(self) }
        return .init(
            type: MessageReactionType(rawValue: type),
            sumScores: Int(sumScores),
            count: Int(count),
            firstReactionAt: firstReactionAt.bridgeDate,
            lastReactionAt: lastReactionAt.bridgeDate
        )
    }
}

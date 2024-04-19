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
}

extension Set where Element == MessageReactionGroupDTO {
    func asModel() -> [MessageReactionType: ChatMessageReactionGroup] {
        reduce(into: [:]) { partialResult, groupDTO in
            partialResult[MessageReactionType(rawValue: groupDTO.type)] = groupDTO.asModel()
        }
    }
}

extension MessageReactionGroupDTO {
    func asModel() -> ChatMessageReactionGroup {
        .init(
            type: MessageReactionType(rawValue: type),
            sumScores: Int(sumScores),
            count: Int(count),
            firstReactionAt: firstReactionAt.bridgeDate,
            lastReactionAt: lastReactionAt.bridgeDate
        )
    }
}

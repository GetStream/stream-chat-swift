//
// Copyright © 2020 Stream.io Inc. All rights reserved.
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
    /// Snapshots the current state of `MessageReactionDTO` and returns an immutable model object from it.
    func asModel<ExtraData: ExtraDataTypes>() -> _ChatMessageReaction<ExtraData> {
        let extraData: ExtraData.MessageReaction
        do {
            extraData = try JSONDecoder.default.decode(ExtraData.MessageReaction.self, from: self.extraData)
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

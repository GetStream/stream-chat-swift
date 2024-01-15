//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

@objc(MessageModerationDetailsDTO)
final class MessageModerationDetailsDTO: NSManagedObject {
    @NSManaged var originalText: String
    @NSManaged var action: String
}

extension MessageModerationDetailsDTO {
    static func create(
        from payload: MessageModerationDetailsPayload,
        context: NSManagedObjectContext
    ) -> MessageModerationDetailsDTO {
        let request = NSFetchRequest<MessageModerationDetailsDTO>(
            entityName: MessageModerationDetailsDTO.entityName
        )
        let new = NSEntityDescription.insertNewObject(into: context, for: request)
        new.action = payload.action
        new.originalText = payload.originalText
        return new
    }
}

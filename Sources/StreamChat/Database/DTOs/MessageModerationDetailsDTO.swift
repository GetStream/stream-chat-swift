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
        isV1: Bool,
        context: NSManagedObjectContext
    ) -> MessageModerationDetailsDTO? {
        let moderationAction = isV1 ? MessageModerationAction(fromV1: payload.action) : MessageModerationAction(fromV2: payload.action)
        let request = NSFetchRequest<MessageModerationDetailsDTO>(
            entityName: MessageModerationDetailsDTO.entityName
        )
        let new = NSEntityDescription.insertNewObject(into: context, for: request)
        new.action = moderationAction.rawValue
        new.originalText = payload.originalText
        return new
    }
}

private extension MessageModerationAction {
    init(fromV1 action: String) {
        switch action {
        case "MESSAGE_RESPONSE_ACTION_BOUNCE":
            self = .bounce
        case "MESSAGE_RESPONSE_ACTION_BLOCK":
            self = .remove
        default:
            self = .init(rawValue: action)
        }
    }

    init(fromV2 action: String) {
        switch action {
        case "bounce":
            self = .bounce
        case "remove":
            self = .remove
        default:
            self = .init(rawValue: action)
        }
    }
}

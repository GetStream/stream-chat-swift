//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

@objc(MessageModerationDetailsDTO)
final class MessageModerationDetailsDTO: NSManagedObject {
    @NSManaged var originalText: String
    @NSManaged var action: String
    @NSManaged var textHarms: [String]?
    @NSManaged var imageHarms: [String]?
    @NSManaged var blocklistsMatched: [String]?
    @NSManaged var semanticFilterMatched: String?
    @NSManaged var platformCircumvented: Bool
}

extension MessageModerationDetailsDTO {
    static func create(
        from payload: MessageModerationDetailsPayload,
        context: NSManagedObjectContext
    ) -> MessageModerationDetailsDTO? {
        let moderationAction = MessageModerationAction(fromV2: payload.action)
        let request = NSFetchRequest<MessageModerationDetailsDTO>(
            entityName: MessageModerationDetailsDTO.entityName
        )
        let new = NSEntityDescription.insertNewObject(into: context, for: request)
        new.action = moderationAction.rawValue
        new.originalText = payload.originalText
        new.textHarms = payload.textHarms
        new.imageHarms = payload.imageHarms
        new.blocklistsMatched = payload.blocklistsMatched
        new.semanticFilterMatched = payload.semanticFilterMatched
        new.platformCircumvented = payload.platformCircumvented ?? false
        return new
    }
}

extension MessageModerationDetails {
    init(fromDTO dto: MessageModerationDetailsDTO) {
        self.init(
            originalText: dto.originalText,
            action: MessageModerationAction(rawValue: dto.action),
            blocklistsMatched: dto.blocklistsMatched,
            textHarms: dto.textHarms,
            imageHarms: dto.imageHarms,
            semanticFilterMatched: dto.semanticFilterMatched,
            platformCircumvented: dto.platformCircumvented
        )
    }
}

private extension MessageModerationAction {
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

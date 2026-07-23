//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

@objc(ChatPreferencesDTO)
final class ChatPreferencesDTO: NSManagedObject {
    @NSManaged var id: String
    @NSManaged var channelMentions: String?
    @NSManaged var defaultPreference: String?
    @NSManaged var directMentions: String?
    @NSManaged var groupMentions: String?
    @NSManaged var hereMentions: String?
    @NSManaged var roleMentions: String?
    @NSManaged var threadReplies: String?
    @NSManaged var pushPreference: PushPreferenceDTO?
}

extension ChatPreferencesDTO {
    static func loadOrCreate(id: String, context: NSManagedObjectContext) -> ChatPreferencesDTO {
        if let existing = load(id: id, context: context) {
            return existing
        }

        let request = fetchRequest(id: id)
        let new = NSEntityDescription.insertNewObject(into: context, for: request)
        new.id = id
        return new
    }

    static func load(id: String, context: NSManagedObjectContext) -> ChatPreferencesDTO? {
        load(by: id, context: context).first as? Self
    }
}

extension NSManagedObjectContext {
    func saveChatPreferences(id: String, payload: ChatPreferences) throws -> ChatPreferencesDTO {
        let dto = ChatPreferencesDTO.loadOrCreate(id: id, context: self)
        dto.channelMentions = payload.channelMentions
        dto.defaultPreference = payload.defaultPreference
        dto.directMentions = payload.directMentions
        dto.groupMentions = payload.groupMentions
        dto.hereMentions = payload.hereMentions
        dto.roleMentions = payload.roleMentions
        dto.threadReplies = payload.threadReplies
        return dto
    }
}

extension ChatPreferences {
    convenience init(fromDTO dto: ChatPreferencesDTO) {
        self.init(
            channelMentions: dto.channelMentions,
            defaultPreference: dto.defaultPreference,
            directMentions: dto.directMentions,
            groupMentions: dto.groupMentions,
            hereMentions: dto.hereMentions,
            roleMentions: dto.roleMentions,
            threadReplies: dto.threadReplies
        )
    }
}

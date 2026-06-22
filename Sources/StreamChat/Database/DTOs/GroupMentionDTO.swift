//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

@objc(GroupMentionDTO)
class GroupMentionDTO: NSManagedObject {
    @NSManaged var id: String
    @NSManaged var name: String
    @NSManaged var messages: Set<MessageDTO>

    static func fetchRequest(id: String) -> NSFetchRequest<GroupMentionDTO> {
        let request = NSFetchRequest<GroupMentionDTO>(entityName: GroupMentionDTO.entityName)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \GroupMentionDTO.id, ascending: true)
        ]
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        return request
    }

    static func load(id: String, context: NSManagedObjectContext) -> GroupMentionDTO? {
        let request = fetchRequest(id: id)
        return try? context.fetch(request).first
    }

    static func loadOrCreate(id: String, context: NSManagedObjectContext) -> GroupMentionDTO {
        if let existing = load(id: id, context: context) {
            return existing
        }

        let request = fetchRequest(id: id)
        return NSEntityDescription.insertNewObject(into: context, for: request)
    }

    func asModel() -> UserGroupMention {
        UserGroupMention(id: id, name: name)
    }
}

extension NSManagedObjectContext {
    @discardableResult
    func saveGroupMention(payload: UserGroupResponse) throws -> GroupMentionDTO {
        let dto = GroupMentionDTO.loadOrCreate(id: payload.id, context: self)
        dto.id = payload.id
        dto.name = payload.name
        return dto
    }
}

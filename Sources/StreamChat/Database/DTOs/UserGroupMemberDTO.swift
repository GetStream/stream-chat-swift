//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

@objc(UserGroupMemberDTO)
class UserGroupMemberDTO: NSManagedObject {
    @NSManaged var id: String
    @NSManaged var appPk: Int64
    @NSManaged var createdAt: DBDate
    @NSManaged var groupId: String
    @NSManaged var isAdmin: Bool
    @NSManaged var userId: String

    @NSManaged var group: UserGroupDTO?

    static func createId(groupId: String, userId: String) -> String {
        [groupId, userId].joined(separator: "/")
    }

    static func fetchRequest(id: String) -> NSFetchRequest<UserGroupMemberDTO> {
        let request = NSFetchRequest<UserGroupMemberDTO>(entityName: UserGroupMemberDTO.entityName)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \UserGroupMemberDTO.id, ascending: true)
        ]
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        return request
    }

    static func load(id: String, context: NSManagedObjectContext) -> UserGroupMemberDTO? {
        let request = fetchRequest(id: id)
        return try? context.fetch(request).first
    }

    static func loadOrCreate(
        id: String,
        context: NSManagedObjectContext
    ) -> UserGroupMemberDTO {
        if let existing = load(id: id, context: context) {
            return existing
        }

        let request = fetchRequest(id: id)
        return NSEntityDescription.insertNewObject(into: context, for: request)
    }

    func asModel() -> UserGroupMember {
        UserGroupMember(
            appPk: Int(appPk),
            createdAt: createdAt.bridgeDate,
            groupId: groupId,
            isAdmin: isAdmin,
            userId: userId
        )
    }
}

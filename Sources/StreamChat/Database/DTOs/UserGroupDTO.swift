//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

@objc(UserGroupDTO)
class UserGroupDTO: NSManagedObject {
    @NSManaged var id: String
    @NSManaged var name: String
    @NSManaged var groupDescription: String?
    @NSManaged var teamId: String?
    @NSManaged var createdAt: DBDate
    @NSManaged var updatedAt: DBDate
    @NSManaged var createdBy: String?
    @NSManaged var membersData: Data?

    static func fetchRequest(id: String) -> NSFetchRequest<UserGroupDTO> {
        let request = NSFetchRequest<UserGroupDTO>(entityName: UserGroupDTO.entityName)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \UserGroupDTO.id, ascending: true)
        ]
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        return request
    }

    static func userGroupsFetchRequest(query: UserGroupListQuery) -> NSFetchRequest<UserGroupDTO> {
        let request = NSFetchRequest<UserGroupDTO>(entityName: UserGroupDTO.entityName)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \UserGroupDTO.id, ascending: true)
        ]

        if let teamId = query.teamId {
            request.predicate = NSPredicate(format: "teamId == %@", teamId)
        }

        return request
    }

    static func load(id: String, context: NSManagedObjectContext) -> UserGroupDTO? {
        let request = fetchRequest(id: id)
        return try? context.fetch(request).first
    }

    static func loadOrCreate(
        id: String,
        context: NSManagedObjectContext
    ) -> UserGroupDTO {
        if let existing = load(id: id, context: context) {
            return existing
        }

        let request = fetchRequest(id: id)
        return NSEntityDescription.insertNewObject(into: context, for: request)
    }
}

private struct StoredUserGroupMember: Codable {
    let groupId: String
    let userId: UserId
    let isAdmin: Bool
    let createdAt: Date
}

extension UserGroupDTO {
    var members: [UserGroupMember] {
        get {
            guard let membersData else { return [] }
            guard let storedMembers = try? JSONDecoder.default.decode([StoredUserGroupMember].self, from: membersData) else {
                return []
            }
            return storedMembers.map {
                UserGroupMember(
                    groupId: $0.groupId,
                    userId: $0.userId,
                    isAdmin: $0.isAdmin,
                    createdAt: $0.createdAt
                )
            }
        }
        set {
            let storedMembers = newValue.map {
                StoredUserGroupMember(
                    groupId: $0.groupId,
                    userId: $0.userId,
                    isAdmin: $0.isAdmin,
                    createdAt: $0.createdAt
                )
            }
            membersData = try? JSONEncoder.default.encode(storedMembers)
        }
    }

    func asModel() -> UserGroup {
        UserGroup(
            id: id,
            name: name,
            description: groupDescription,
            teamId: teamId,
            members: members,
            createdAt: createdAt.bridgeDate,
            updatedAt: updatedAt.bridgeDate,
            createdBy: createdBy
        )
    }
}

extension NSManagedObjectContext: UserGroupDatabaseSession {
    @discardableResult
    func saveUserGroup(payload: UserGroupPayload) throws -> UserGroupDTO {
        let dto = UserGroupDTO.loadOrCreate(id: payload.id, context: self)
        dto.id = payload.id
        dto.name = payload.name
        dto.groupDescription = payload.description
        dto.teamId = payload.teamId
        dto.createdAt = payload.createdAt.bridgeDate
        dto.updatedAt = payload.updatedAt.bridgeDate
        dto.createdBy = payload.createdBy
        dto.members = payload.members.map { $0.asModel() }
        return dto
    }

    func deleteUserGroup(id: String) {
        guard let dto = UserGroupDTO.load(id: id, context: self) else { return }
        delete(dto)
    }
}

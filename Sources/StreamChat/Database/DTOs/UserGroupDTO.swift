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
    @NSManaged var memberDTOs: Set<UserGroupMemberDTO>

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

extension UserGroupDTO {
    var members: [UserGroupMember] {
        memberDTOs
            .sorted { $0.userId < $1.userId }
            .map { $0.asModel() }
    }

    func asModel() -> UserGroup {
        UserGroup(
            createdAt: createdAt.bridgeDate,
            createdBy: createdBy,
            description: groupDescription,
            id: id,
            members: members,
            name: name,
            teamId: teamId,
            updatedAt: updatedAt.bridgeDate
        )
    }
}

extension NSManagedObjectContext: UserGroupDatabaseSession {
    @discardableResult
    func saveUserGroup(payload: UserGroup) throws -> UserGroupDTO {
        let dto = UserGroupDTO.loadOrCreate(id: payload.id, context: self)
        dto.id = payload.id
        dto.name = payload.name
        dto.groupDescription = payload.description
        dto.teamId = payload.teamId
        dto.createdAt = payload.createdAt.bridgeDate
        dto.updatedAt = payload.updatedAt.bridgeDate
        dto.createdBy = payload.createdBy
        dto.memberDTOs = try Set(payload.members.map { try saveUserGroupMember(payload: $0) })
        return dto
    }

    @discardableResult
    func saveUserGroupMember(payload: UserGroupMember) throws -> UserGroupMemberDTO {
        let id = UserGroupMemberDTO.createId(groupId: payload.groupId, userId: payload.userId)
        let dto = UserGroupMemberDTO.loadOrCreate(id: id, context: self)
        dto.id = id
        dto.appPk = Int64(payload.appPk)
        dto.createdAt = payload.createdAt.bridgeDate
        dto.groupId = payload.groupId
        dto.isAdmin = payload.isAdmin
        dto.userId = payload.userId
        return dto
    }

    func deleteUserGroup(id: String) {
        guard let dto = UserGroupDTO.load(id: id, context: self) else { return }
        delete(dto)
    }
}

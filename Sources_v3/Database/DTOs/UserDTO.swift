//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

@objc(UserDTO)
class UserDTO: NSManagedObject {
    @NSManaged var extraData: Data
    @NSManaged var id: String
    @NSManaged var isBanned: Bool
    @NSManaged var isOnline: Bool
    @NSManaged var lastActivityAt: Date?
    
    @NSManaged var userCreatedAt: Date
    @NSManaged var userRoleRaw: String
    @NSManaged var userUpdatedAt: Date
    
    /// Returns a fetch request for the dto with the provided `userId`.
    static func user(withID userId: UserId) -> NSFetchRequest<UserDTO> {
        let request = NSFetchRequest<UserDTO>(entityName: UserDTO.entityName)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \UserDTO.id, ascending: false)]
        request.predicate = NSPredicate(format: "id == %@", userId)
        return request
    }
}

extension UserDTO: EphemeralValuesContainer {
    func resetEphemeralValues() {
        isOnline = false
    }
}

extension UserDTO {
    /// Fetches and returns `UserDTO` with the given id. Returns `nil` if the entity doesn't exist.
    ///
    /// - Parameters:
    ///   - id: The id of the user to fetch
    ///   - context: The context used to fetch `UserDTO`
    ///
    fileprivate static func load(id: String, context: NSManagedObjectContext) -> UserDTO? {
        let request = NSFetchRequest<UserDTO>(entityName: UserDTO.entityName)
        request.predicate = NSPredicate(format: "id == %@", id)
        return try? context.fetch(request).first
    }
    
    /// If a User with the given id exists in the context, fetches and returns it. Otherwise creates a new
    /// `UserDTO` with the given id.
    ///
    /// - Parameters:
    ///   - id: The id of the user to fetch
    ///   - context: The context used to fetch/create `UserDTO`
    ///
    static func loadOrCreate(id: String, context: NSManagedObjectContext) -> UserDTO {
        if let existing = Self.load(id: id, context: context) {
            return existing
        }
        
        let new = NSEntityDescription.insertNewObject(forEntityName: Self.entityName, into: context) as! UserDTO
        new.id = id
        return new
    }
}

extension NSManagedObjectContext: UserDatabaseSession {
    func user(id: UserId) -> UserDTO? {
        UserDTO.load(id: id, context: self)
    }
    
    func saveUser<ExtraData: UserExtraData>(
        payload: UserPayload<ExtraData>,
        query: UserListQuery<ExtraData>?
    ) throws -> UserDTO {
        let dto = UserDTO.loadOrCreate(id: payload.id, context: self)
        
        dto.isBanned = payload.isBanned
        dto.isOnline = payload.isOnline
        dto.lastActivityAt = payload.lastActiveAt
        dto.userCreatedAt = payload.createdAt
        dto.userRoleRaw = payload.role.rawValue
        dto.userUpdatedAt = payload.updatedAt
        
        // TODO: TEAMS
        
        dto.extraData = try JSONEncoder.default.encode(payload.extraData)
        
        if let query = query {
            let queryDTO = saveQuery(query: query)
            queryDTO.users.insert(dto)
        }
        
        return dto
    }
    
    func updateQuery(
        for userId: UserId,
        queryFilterHash: String
    ) {
        if let userDTO = user(id: userId),
            let queryDTO = userListQuery(filterHash: queryFilterHash) {
            queryDTO.users.insert(userDTO)
        }
    }
}

extension UserDTO {
    /// Snapshots the current state of `UserDTO` and returns an immutable model object from it.
    func asModel<ExtraData: UserExtraData>() -> _ChatUser<ExtraData> { .create(fromDTO: self) }
    
    /// Snapshots the current state of `UserDTO` and returns its representation for used in API calls.
    func asRequestBody<ExtraData: UserExtraData>() -> UserRequestBody<ExtraData> {
        var extraData: ExtraData?
        do {
            extraData = try JSONDecoder.default.decode(ExtraData.self, from: self.extraData)
        } catch {
            log.assertationFailure(
                "Failed decoding saved extra data with error: \(error). This should never happen because"
                    + "the extra data must be a valid JSON to be saved."
            )
        }
        
        return .init(id: id, extraData: extraData ?? .defaultValue)
    }
}

extension UserDTO {
    static func userListFetchRequest(query: UserListQuery) -> NSFetchRequest<UserDTO> {
        let request = NSFetchRequest<UserDTO>(entityName: UserDTO.entityName)
        
        // Fetch results controller requires at least one sorting descriptor.
        let sortDescriptors = query.sort.compactMap { $0.key.sortDescriptor(isAscending: $0.isAscending) }
        request.sortDescriptors = sortDescriptors.isEmpty ? [UserListSortingKey.defaultSortDescriptor] : sortDescriptors
                
        request.predicate = NSPredicate(format: "ANY queries.filterHash == %@", query.filter?.filterHash ?? Filter.nilFilterHash)
        return request
    }

    static var userWithoutQueryFetchRequest: NSFetchRequest<UserDTO> {
        let request = NSFetchRequest<UserDTO>(entityName: UserDTO.entityName)
        request.sortDescriptors = [UserListSortingKey.defaultSortDescriptor]
        request.predicate = NSPredicate(format: "queries.@count == 0")
        return request
    }
}

extension _ChatUser {
    fileprivate static func create(fromDTO dto: UserDTO) -> _ChatUser {
        let extraData: ExtraData
        do {
            extraData = try JSONDecoder.default.decode(ExtraData.self, from: dto.extraData)
        } catch {
            log.error("Failed to decode extra data for User with id: <\(dto.id)>, using default value instead. Error: \(error)")
            extraData = .defaultValue
        }
        
        return _ChatUser(
            id: dto.id,
            isOnline: dto.isOnline,
            isBanned: dto.isBanned,
            userRole: UserRole(rawValue: dto.userRoleRaw)!,
            createdAt: dto.userCreatedAt,
            updatedAt: dto.userUpdatedAt,
            lastActiveAt: dto.lastActivityAt,
            extraData: extraData
        )
    }
}

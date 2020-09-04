//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

@objc(UserDTO)
class UserDTO: NSManagedObject {
    static let entityName: String = "UserDTO"
    
    @NSManaged var extraData: Data
    @NSManaged var id: String
    @NSManaged var isBanned: Bool
    @NSManaged var isOnline: Bool
    @NSManaged var lastActivityAt: Date?
    
    @NSManaged var userCreatedAt: Date
    @NSManaged var userRoleRaw: String
    @NSManaged var userUpdatedAt: Date
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
    
    func saveUser<ExtraUserData: Codable & Hashable>(payload: UserPayload<ExtraUserData>) throws -> UserDTO {
        let dto = UserDTO.loadOrCreate(id: payload.id, context: self)
        
        dto.isBanned = payload.isBanned
        dto.isOnline = payload.isOnline
        dto.lastActivityAt = payload.lastActiveAt
        dto.userCreatedAt = payload.createdAt
        dto.userRoleRaw = payload.role.rawValue
        dto.userUpdatedAt = payload.updatedAt
        
        // TODO: TEAMS
        
        dto.extraData = try JSONEncoder.default.encode(payload.extraData)
        
        return dto
    }
}

extension UserDTO {
    /// Snapshots the current state of `UserDTO` and returns an immutable model object from it.
    func asModel<ExtraData: UserExtraData>() -> UserModel<ExtraData> { .create(fromDTO: self) }
    
    /// Snapshots the current state of `UserDTO` and returns its representation for used in API calls.
    func asRequestBody<ExtraData: UserExtraData>() -> UserRequestBody<ExtraData> {
        var extraData: ExtraData?
        do {
            extraData = try JSONDecoder.default.decode(ExtraData.self, from: self.extraData)
        } catch {
            log.assert(
                false,
                "Failed decoding saved extra data with error: \(error). This should never happen because"
                    + "the extra data must be a valid JSON to be saved."
            )
        }
        
        return .init(id: id, extraData: extraData ?? .defaultValue)
    }
}

extension UserModel {
    fileprivate static func create(fromDTO dto: UserDTO) -> UserModel {
        let extraData: ExtraData
        do {
            extraData = try JSONDecoder.default.decode(ExtraData.self, from: dto.extraData)
        } catch {
            fatalError(
                "Failed decoding saved extra data with error: \(error). This should never happen because"
                    + "the extra data must be a valid JSON to be saved."
            )
        }
        
        return UserModel(
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

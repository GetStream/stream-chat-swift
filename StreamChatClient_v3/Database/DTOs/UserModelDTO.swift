//
// UserModelDTO.swift
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
    @NSManaged var lastActivityDate: Date?
    @NSManaged var teams: String
    @NSManaged var userCreatedDate: Date
    @NSManaged var userRoleRaw: String
    @NSManaged var userUpdatedDate: Date
}

extension UserDTO {
    /// Fetches and returns `UserDTO` with the given id. Returns `nil` if the entity doesn't extist.
    ///
    /// - Parameters:
    ///   - id: The id of the user to fetch
    ///   - context: The context used to fetch/create `UserDTO`
    ///
    static func load(id: String, context: NSManagedObjectContext) -> UserDTO? {
        let request = NSFetchRequest<UserDTO>(entityName: UserDTO.entityName)
        request.predicate = NSPredicate(format: "id == %@", id)
        return try? context.fetch(request).first
    }
    
    /// If a User with the given id exists in the context, fetches and returns it. Otherwise create a new
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

extension NSManagedObjectContext {
    func saveUser<ExtraUserData: Codable & Hashable>(payload: UserPayload<ExtraUserData>) throws -> UserDTO {
        let dto = UserDTO.loadOrCreate(id: payload.id, context: self)
        
        dto.isBanned = payload.isBanned
        dto.isOnline = payload.isOnline
        dto.lastActivityDate = payload.lastActiveDate
        dto.userCreatedDate = payload.created
        dto.userRoleRaw = payload.roleRawValue
        dto.userUpdatedDate = payload.updated
        
        // TODO: TEAMS
        
        dto.extraData = try JSONEncoder.default.encode(payload.extraData)
        
        return dto
    }
    
    func loadUser<ExtraData: UserExtraData>(id: String) -> UserModel<ExtraData>? {
        guard let dto = UserDTO.load(id: id, context: self) else { return nil }
        return .create(fromDTO: dto)
    }
}

extension UserModel {
    static func create(fromDTO dto: UserDTO) -> UserModel {
        let extraData: ExtraData
        do {
            extraData = try JSONDecoder.default.decode(ExtraData.self, from: dto.extraData)
        } catch {
            fatalError("Failed decoding saved extra data with error: \(error). This should never happen because"
                + "the extra data must be a valid JSON to be saved.")
        }
        
        return UserModel(id: dto.id,
                         isOnline: dto.isOnline,
                         isBanned: dto.isBanned,
                         userRole: UserRole(rawValue: dto.userRoleRaw)!,
                         createdDate: dto.userCreatedDate,
                         updatedDate: dto.userUpdatedDate,
                         lastActiveDate: dto.lastActivityDate,
                         extraData: extraData)
    }
}

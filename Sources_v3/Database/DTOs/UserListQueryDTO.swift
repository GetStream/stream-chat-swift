//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData

@objc(UserListQueryDTO)
class UserListQueryDTO: NSManagedObject {
    /// Unique identifier of the query.
    @NSManaged var queryHash: String
    
    /// Serialized `Filter` JSON which can be used in cases the query needs to be repeated.
    @NSManaged var filterJSONData: Data
    
    // MARK: - Relationships
    
    @NSManaged var users: Set<UserDTO>
    
    static func load(queryHash: String, context: NSManagedObjectContext) -> UserListQueryDTO? {
        let request = NSFetchRequest<UserListQueryDTO>(entityName: UserListQueryDTO.entityName)
        request.predicate = NSPredicate(format: "queryHash == %@", queryHash)
        return try? context.fetch(request).first
    }
    
    static func loadOrCreate(queryHash: String, context: NSManagedObjectContext) -> UserListQueryDTO {
        if let existing = Self.load(queryHash: queryHash, context: context) {
            return existing
        }
        
        let new = UserListQueryDTO(context: context)
        new.queryHash = queryHash
        return new
    }
}

extension NSManagedObjectContext {
    func userListQuery(queryHash: String) -> UserListQueryDTO? {
        UserListQueryDTO.load(queryHash: queryHash, context: self)
    }
    
    func saveQuery<ExtraData: UserExtraData>(query: UserListQuery<ExtraData>) -> UserListQueryDTO {
        let dto = UserListQueryDTO.loadOrCreate(queryHash: query.queryHash, context: self)
        
        do {
            dto.filterJSONData = try JSONEncoder.default.encode(query.filter)
        } catch {
            log.error("Failed encoding query Filter data with error: \(error).")
        }
        
        return dto
    }
}

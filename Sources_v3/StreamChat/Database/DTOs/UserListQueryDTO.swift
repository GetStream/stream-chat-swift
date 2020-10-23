//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData

@objc(UserListQueryDTO)
class UserListQueryDTO: NSManagedObject {
    /// Unique identifier of the query.
    @NSManaged var filterHash: String
    
    /// Serialized `Filter` JSON which can be used in cases the query needs to be repeated.
    @NSManaged var filterJSONData: Data
    
    // MARK: - Relationships
    
    @NSManaged var users: Set<UserDTO>
    
    static func load(filterHash: String, context: NSManagedObjectContext) -> UserListQueryDTO? {
        let request = NSFetchRequest<UserListQueryDTO>(entityName: UserListQueryDTO.entityName)
        request.predicate = NSPredicate(format: "filterHash == %@", filterHash)
        return try? context.fetch(request).first
    }
}

extension NSManagedObjectContext {
    func userListQuery(filterHash: String) -> UserListQueryDTO? {
        UserListQueryDTO.load(filterHash: filterHash, context: self)
    }
    
    func saveQuery<ExtraData: UserExtraData>(query: UserListQuery<ExtraData>) throws -> UserListQueryDTO? {
        guard let filterHash = query.filter?.filterHash else {
            // A query without a filter doesn't have to be saved to the DB because it matches all users by default.
            return nil
        }
        
        if let existingDTO = UserListQueryDTO.load(filterHash: filterHash, context: self) {
            return existingDTO
        }
        
        let newDTO = NSEntityDescription
            .insertNewObject(forEntityName: UserListQueryDTO.entityName, into: self) as! UserListQueryDTO
        newDTO.filterHash = filterHash
        
        do {
            newDTO.filterJSONData = try JSONEncoder.default.encode(query.filter)
        } catch {
            log.error("Failed encoding query Filter data with error: \(error).")
        }
        
        return newDTO
    }
}

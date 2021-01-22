//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData

@objc(UserListQueryDTO)
class UserListQueryDTO: NSManagedObject {
    /// Unique identifier of the query.
    @NSManaged var filterHash: String
    
    /// Serialized `Filter` JSON which can be used in cases the query needs to be repeated.
    @NSManaged var filterJSONData: Data
    
    /// Indicates if the query should be observed by background workers.
    /// If set to true, newly created users in the database are automatically included in the query if they fit the predicate.
    @NSManaged var shouldBeUpdatedInBackground: Bool
    
    // MARK: - Relationships
    
    @NSManaged var users: Set<UserDTO>
    
    static func observedQueries() -> NSFetchRequest<UserListQueryDTO> {
        let fetchRequest = NSFetchRequest<UserListQueryDTO>(entityName: UserListQueryDTO.entityName)
        fetchRequest.predicate = NSPredicate(format: "shouldBeUpdatedInBackground == YES")
        return fetchRequest
    }
    
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
    
    func saveQuery<ExtraData: UserExtraData>(query: _UserListQuery<ExtraData>) throws -> UserListQueryDTO? {
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
        newDTO.shouldBeUpdatedInBackground = query.shouldBeUpdatedInBackground
        
        do {
            newDTO.filterJSONData = try JSONEncoder.default.encode(query.filter)
        } catch {
            log.error("Failed encoding query Filter data with error: \(error).")
        }
        
        return newDTO
    }
    
    func deleteQuery<ExtraData: UserExtraData>(_ query: _UserListQuery<ExtraData>) {
        guard let filterHash = query.filter?.filterHash else {
            // A query without a filter is not saved in DB.
            return
        }
        
        guard let existingDTO = UserListQueryDTO.load(filterHash: filterHash, context: self) else {
            // This query doesn't exist in DB.
            return
        }
        
        delete(existingDTO)
    }
}

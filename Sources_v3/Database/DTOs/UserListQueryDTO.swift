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
    func saveQuery(query: UserListQuery) -> UserListQueryDTO {
        if let existingDTO = UserListQueryDTO.load(filterHash: query.filter.filterHash, context: self) {
            return existingDTO
        }
        
        let newDTO = NSEntityDescription
            .insertNewObject(forEntityName: UserListQueryDTO.entityName, into: self) as! UserListQueryDTO
        newDTO.filterHash = query.filter.filterHash
        
        let jsonData: Data
        do {
            jsonData = try JSONEncoder().encode(query.filter)
        } catch {
            log.error("Failed encoding query Filter data with error: \(error). Using 'none' filter instead.")
            jsonData = try! JSONEncoder().encode(Filter.none)
        }
        
        newDTO.filterJSONData = jsonData
        
        return newDTO
    }
}

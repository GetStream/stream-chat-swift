//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData

@objc(MessageSearchQueryDTO)
class MessageSearchQueryDTO: NSManagedObject {
    /// Unique identifier of the query/
    @NSManaged var filterHash: String
    
    @NSManaged var messages: Set<MessageDTO>
    
    static func load(filterHash: String, context: NSManagedObjectContext) -> MessageSearchQueryDTO? {
        let request = NSFetchRequest<MessageSearchQueryDTO>(entityName: MessageSearchQueryDTO.entityName)
        request.predicate = NSPredicate(format: "filterHash == %@", filterHash)
        return try? context.fetch(request).first
    }
}

extension NSManagedObjectContext {
    func messageSearchQuery(filterHash: String) -> MessageSearchQueryDTO? {
        MessageSearchQueryDTO.load(filterHash: filterHash, context: self)
    }
    
    func saveQuery(query: MessageSearchQuery) -> MessageSearchQueryDTO {
        if let existingDTO = MessageSearchQueryDTO.load(filterHash: query.filterHash, context: self) {
            return existingDTO
        }
        
        let newDTO = NSEntityDescription
            .insertNewObject(forEntityName: MessageSearchQueryDTO.entityName, into: self) as! MessageSearchQueryDTO
        newDTO.filterHash = query.filterHash
        
        return newDTO
    }
    
    func deleteQuery(_ query: MessageSearchQuery) {
        guard let existingDTO = MessageSearchQueryDTO.load(filterHash: query.filterHash, context: self) else {
            // This query doesn't exist in DB.
            return
        }
        
        delete(existingDTO)
    }
}

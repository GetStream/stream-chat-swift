//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import CoreData

@objc(MessageSearchQueryDTO)
class MessageSearchQueryDTO: NSManagedObject {
    /// Unique identifier of the query/
    @NSManaged var filterHash: String?
    
    @NSManaged var messages: Set<MessageDTO>
    
    static func load(filterHash: String, context: NSManagedObjectContext) -> MessageSearchQueryDTO? {
        load(keyPath: "filterHash", equalTo: filterHash, context: context).first
    }
}

extension NSManagedObjectContext: MessageSearchDatabaseSession {
    func messageSearchQuery(filterHash: String) -> MessageSearchQueryDTO? {
        MessageSearchQueryDTO.load(filterHash: filterHash, context: self)
    }
    
    func saveQuery(query: MessageSearchQuery) -> MessageSearchQueryDTO {
        let request = MessageSearchQueryDTO.fetchRequest(keyPath: "filterHash", equalTo: query.filterHash)
        if let existingDTO = MessageSearchQueryDTO.load(by: request, context: self).first {
            return existingDTO
        }
        
        let newDTO = NSEntityDescription
            .insertNewObject(
                forEntityName: MessageSearchQueryDTO.entityName,
                into: self,
                forRequest: request,
                cachingInto: FetchCache.shared
            ) as! MessageSearchQueryDTO
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

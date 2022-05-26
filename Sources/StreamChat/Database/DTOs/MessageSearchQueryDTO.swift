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
        load(
            keyPath: #keyPath(MessageSearchQueryDTO.filterHash),
            equalTo: filterHash,
            context: context
        ).first
    }
}

extension NSManagedObjectContext: MessageSearchDatabaseSession {
    func messageSearchQuery(filterHash: String) -> MessageSearchQueryDTO? {
        MessageSearchQueryDTO.load(filterHash: filterHash, context: self)
    }
    
    func saveQuery(query: MessageSearchQuery) -> MessageSearchQueryDTO {
        if let existingDTO = MessageSearchQueryDTO.load(filterHash: query.filterHash, context: self) {
            return existingDTO
        }
        
        let request = MessageSearchQueryDTO.fetchRequest(
            keyPath: #keyPath(MessageSearchQueryDTO.filterHash),
            equalTo: query.filterHash
        )
        let newDTO = NSEntityDescription.insertNewObject(into: self, for: request)
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

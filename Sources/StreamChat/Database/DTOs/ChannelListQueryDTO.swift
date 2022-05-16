//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import CoreData

@objc(ChannelListQueryDTO)
class ChannelListQueryDTO: NSManagedObject {
    /// Unique identifier of the query/
    @NSManaged var filterHash: String
    
    /// Serialized `Filter` JSON which can be used in cases the query needs to be repeated, i.e. for newly created channels.
    @NSManaged var filterJSONData: Data
    
    // MARK: - Relationships
    
    @NSManaged var channels: Set<ChannelDTO>
    
    static func load(filterHash: String, context: NSManagedObjectContext) -> ChannelListQueryDTO? {
        load(
            keyPath: #keyPath(ChannelListQueryDTO.filterHash),
            equalTo: filterHash,
            context: context
        ).first
    }
    
    /// The fetch request that returns all existed queries from the database.
    static var allQueriesFetchRequest: NSFetchRequest<ChannelListQueryDTO> {
        let request = NSFetchRequest<ChannelListQueryDTO>(entityName: ChannelListQueryDTO.entityName)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \ChannelListQueryDTO.filterHash, ascending: false)
        ]
        return request
    }
}

extension NSManagedObjectContext {
    func channelListQuery(filterHash: String) -> ChannelListQueryDTO? {
        ChannelListQueryDTO.load(filterHash: filterHash, context: self)
    }
    
    func saveQuery(query: ChannelListQuery) -> ChannelListQueryDTO {
        let request = ChannelListQueryDTO.fetchRequest(keyPath: "filterHash", equalTo: query.filter.filterHash)
        if let existingDTO = ChannelListQueryDTO.load(by: request, context: self).first {
            return existingDTO
        }
        
        let newDTO = NSEntityDescription.insertNewObject(into: self, for: request)
        newDTO.filterHash = query.filter.filterHash
        
        let jsonData: Data
        do {
            jsonData = try JSONEncoder.default.encode(query.filter)
        } catch {
            log.error("Failed encoding query Filter data with error: \(error).")
            jsonData = Data()
        }
        
        newDTO.filterJSONData = jsonData
        
        return newDTO
    }
    
    func loadAllChannelListQueries() -> [ChannelListQueryDTO] {
        let queries: [ChannelListQueryDTO]
        
        do {
            queries = try fetch(ChannelListQueryDTO.allQueriesFetchRequest)
        } catch {
            log.error("Failed to load channel list queries from the database: \(error).")
            queries = []
        }
        
        return queries
    }
}

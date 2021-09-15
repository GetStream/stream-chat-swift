//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData

@objc(ChannelListQueryDTO)
class ChannelListQueryDTO: NSManagedObject {
    /// Unique identifier of the query/
    @NSManaged var queryHash: String
    
    /// Serialized `Filter` JSON which can be used in cases the query needs to be repeated, i.e. for newly created channels.
    @NSManaged var filterJSONData: Data
    
    /// Serialized `[Sorting<ChannelListSortingKey>]` JSON which can be used in cases the query needs to be repeated, i.e. when connection comes back.
    @NSManaged var sortingJSONData: Data
    
    // MARK: - Relationships
    
    @NSManaged var channels: Set<ChannelDTO>
    
    static func allQueriesFetchRequest() -> NSFetchRequest<ChannelListQueryDTO> {
        let request = NSFetchRequest<ChannelListQueryDTO>(entityName: ChannelListQueryDTO.entityName)
        request.sortDescriptors = [.init(keyPath: \ChannelListQueryDTO.queryHash, ascending: true)]
        return request
    }
    
    static func load(queryHash: String, context: NSManagedObjectContext) -> ChannelListQueryDTO? {
        let request = NSFetchRequest<ChannelListQueryDTO>(entityName: ChannelListQueryDTO.entityName)
        request.predicate = NSPredicate(format: "queryHash == %@", queryHash)
        return try? context.fetch(request).first
    }
}

extension NSManagedObjectContext: ChannelListQueryDatabaseSession {
    func channelListQuery(queryHash: String) -> ChannelListQueryDTO? {
        ChannelListQueryDTO.load(queryHash: queryHash, context: self)
    }
    
    func saveQuery(query: ChannelListQuery) -> ChannelListQueryDTO {
        if let existingDTO = channelListQuery(queryHash: query.queryHash) {
            return existingDTO
        }
        
        let newDTO = NSEntityDescription
            .insertNewObject(forEntityName: ChannelListQueryDTO.entityName, into: self) as! ChannelListQueryDTO
        newDTO.queryHash = query.queryHash
        
        do {
            newDTO.sortingJSONData = try JSONEncoder.default.encode(query.sort)
        } catch {
            log.error("Failed encoding query sort data with error: \(error).")
            newDTO.sortingJSONData = Data()
        }
        
        do {
            newDTO.filterJSONData = try JSONEncoder.default.encode(query.filter)
        } catch {
            log.error("Failed encoding query Filter data with error: \(error).")
            newDTO.filterJSONData = Data()
        }
        
        return newDTO
    }
    
    func loadChannelListQueries() -> [ChannelListQueryDTO] {
        let request = ChannelListQueryDTO.allQueriesFetchRequest()
        do {
            return try fetch(request)
        } catch {
            log.assertionFailure("Failed to load channel list queries")
            return []
        }
    }
}

extension ChannelListQueryDTO {
    func asModel() -> ChannelListQuery? {
        do {
            let decoder = JSONDecoder.default
            
            var query = ChannelListQuery(
                filter: try decoder.decode(
                    Filter<ChannelListFilterScope>.self,
                    from: filterJSONData
                ),
                sort: try decoder.decode(
                    [Sorting<ChannelListSortingKey>].self,
                    from: sortingJSONData
                )
            )
            
            query.explicitHash = queryHash
            
            return query
        } catch {
            log.error("Internal error. Failed to decode channel list query: \(error)")
            return nil
        }
    }
}

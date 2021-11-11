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
    
    // MARK: - Relationships
    
    @NSManaged var channels: Set<ChannelDTO>
    
    /// Channels that are being read by the current user (the subset of `channels`)
    @NSManaged var openChannels: Set<ChannelDTO>
    
    static func load(queryHash: String, context: NSManagedObjectContext) -> ChannelListQueryDTO? {
        let request = NSFetchRequest<ChannelListQueryDTO>(entityName: ChannelListQueryDTO.entityName)
        request.predicate = NSPredicate(format: "queryHash == %@", queryHash)
        return try? context.fetch(request).first
    }
}

extension NSManagedObjectContext {
    func channelListQuery(queryHash: String) -> ChannelListQueryDTO? {
        ChannelListQueryDTO.load(queryHash: queryHash, context: self)
    }
    
    func saveQuery(query: ChannelListQuery) -> ChannelListQueryDTO {
        if let existingDTO = ChannelListQueryDTO.load(queryHash: query.queryHash, context: self) {
            return existingDTO
        }
        
        let newDTO = NSEntityDescription
            .insertNewObject(forEntityName: ChannelListQueryDTO.entityName, into: self) as! ChannelListQueryDTO
        newDTO.queryHash = query.queryHash
        
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
}

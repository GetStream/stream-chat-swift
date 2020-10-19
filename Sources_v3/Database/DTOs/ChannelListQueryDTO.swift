//
// Copyright © 2020 Stream.io Inc. All rights reserved.
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
    
    static func load(queryHash: String, context: NSManagedObjectContext) -> ChannelListQueryDTO? {
        let request = NSFetchRequest<ChannelListQueryDTO>(entityName: ChannelListQueryDTO.entityName)
        request.predicate = NSPredicate(format: "queryHash == %@", queryHash)
        return try? context.fetch(request).first
    }
    
    static func loadOrCreate(queryHash: String, context: NSManagedObjectContext) -> ChannelListQueryDTO {
        if let existing = Self.load(queryHash: queryHash, context: context) {
            return existing
        }
        
        let new = ChannelListQueryDTO(context: context)
        new.queryHash = queryHash
        return new
    }
}

extension NSManagedObjectContext {
    func channelListQuery(queryHash: String) -> ChannelListQueryDTO? {
        ChannelListQueryDTO.load(queryHash: queryHash, context: self)
    }
    
    func saveQuery<ExtraData: ExtraDataTypes>(query: ChannelListQuery<ExtraData>) -> ChannelListQueryDTO {
        let dto = ChannelListQueryDTO.loadOrCreate(queryHash: query.queryHash, context: self)
        
        let jsonData: Data
        do {
            jsonData = try JSONEncoder.default.encode(query.filter)
        } catch {
            log.error("Failed encoding query Filter data with error: \(error).")
            jsonData = Data()
        }
        
        dto.filterJSONData = jsonData
        
        return dto
    }
}

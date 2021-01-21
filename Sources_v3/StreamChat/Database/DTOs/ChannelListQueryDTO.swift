//
// Copyright © 2021 Stream.io Inc. All rights reserved.
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
        let request = NSFetchRequest<ChannelListQueryDTO>(entityName: ChannelListQueryDTO.entityName)
        request.predicate = NSPredicate(format: "filterHash == %@", filterHash)
        return try? context.fetch(request).first
    }
}

extension NSManagedObjectContext {
    func channelListQuery(filterHash: String) -> ChannelListQueryDTO? {
        ChannelListQueryDTO.load(filterHash: filterHash, context: self)
    }
    
    func saveQuery<ExtraData: ChannelExtraData>(query: _ChannelListQuery<ExtraData>) -> ChannelListQueryDTO {
        if let existingDTO = ChannelListQueryDTO.load(filterHash: query.filter.filterHash, context: self) {
            return existingDTO
        }
        
        let newDTO = NSEntityDescription
            .insertNewObject(forEntityName: ChannelListQueryDTO.entityName, into: self) as! ChannelListQueryDTO
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
}

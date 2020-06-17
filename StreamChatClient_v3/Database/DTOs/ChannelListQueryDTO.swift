//
// ChannelListQueryDTO.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData

@objc(ChannelListQueryDTO)
class ChannelListQueryDTO: NSManagedObject {
    static let entityName = "ChannelListQueryDTO"
    
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
    
    static func loadOrCreate(filterHash: String, context: NSManagedObjectContext) -> ChannelListQueryDTO {
        if let existing = Self.load(filterHash: filterHash, context: context) {
            return existing
        }
        
        let new = NSEntityDescription.insertNewObject(forEntityName: Self.entityName, into: context) as! ChannelListQueryDTO
        new.filterHash = filterHash
        return new
    }
}

extension NSManagedObjectContext {
    func saveQuery(query: ChannelListQuery) -> ChannelListQueryDTO {
        let dto = ChannelListQueryDTO.loadOrCreate(filterHash: query.filter.filterHash, context: self)
        
        let jsonData: Data
        do {
            jsonData = try JSONEncoder().encode(query.filter)
        } catch {
            log.error("Failed encoding query Filter data with error: \(error). Using 'none' filter instead.")
            jsonData = try! JSONEncoder().encode(Filter.none)
        }
        
        dto.filterJSONData = jsonData
        
        return dto
    }
}

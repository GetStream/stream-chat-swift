//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import CoreData

@objc(ChannelMemberListQueryDTO)
final class ChannelMemberListQueryDTO: NSManagedObject {
    /// Unique identifier of the query.
    @NSManaged var queryHash: String
    
    /// Serialized `Filter` JSON which can be used in cases the query needs to be repeated.
    @NSManaged var filterJSONData: Data?
    
    /// The channel the query works with.
    @NSManaged var channel: ChannelDTO
        
    /// A set of members matching the query.
    @NSManaged var members: Set<MemberDTO>
        
    static func load(queryHash: String, context: NSManagedObjectContext) -> ChannelMemberListQueryDTO? {
        load(
            keyPath: #keyPath(ChannelMemberListQueryDTO.queryHash),
            equalTo: queryHash,
            context: context
        ).first
    }
    
    static func loadOrCreate(queryHash: String, context: NSManagedObjectContext) -> ChannelMemberListQueryDTO {
        let request = fetchRequest(keyPath: "queryHash", equalTo: queryHash)
        if let existing = load(by: request, context: context).first {
            return existing
        }
        
        let new = NSEntityDescription.insertNewObject(
            forEntityName: Self.entityName,
            into: context,
            forRequest: request,
            cachingInto: FetchCache.shared
        ) as! ChannelMemberListQueryDTO
        new.queryHash = queryHash
        return new
    }
}

extension NSManagedObjectContext: MemberListQueryDatabaseSession {
    func channelMemberListQuery(queryHash: String) -> ChannelMemberListQueryDTO? {
        ChannelMemberListQueryDTO.load(queryHash: queryHash, context: self)
    }
    
    func saveQuery(_ query: ChannelMemberListQuery) throws -> ChannelMemberListQueryDTO {
        guard let channelDTO = channel(cid: query.cid) else {
            throw ClientError.ChannelDoesNotExist(cid: query.cid)
        }
        
        let dto = ChannelMemberListQueryDTO.loadOrCreate(queryHash: query.queryHash, context: self)
        dto.channel = channelDTO

        var jsonData: Data?
        do {
            // On iOS 12 attempt of encoding nil value will produce an error.
            // We can remove this nil check after dropping iOS 12 support.
            jsonData = query.filter == nil ? nil : try JSONEncoder.default.encode(query.filter)
        } catch {
            log.error("Failed encoding query Filter data with error: \(error). Using 'none' filter instead.")
        }
        
        dto.filterJSONData = jsonData
        
        return dto
    }
}

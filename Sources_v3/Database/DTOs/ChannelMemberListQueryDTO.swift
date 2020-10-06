//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData

@objc(ChannelMemberListQueryDTO)
final class ChannelMemberListQueryDTO: NSManagedObject {
    /// Unique identifier of the query.
    @NSManaged var queryHash: String
    
    /// Serialized `Filter` JSON which can be used in cases the query needs to be repeated.
    @NSManaged var filterJSONData: Data
    
    /// The channel the query works with.
    @NSManaged var channel: ChannelDTO
        
    /// Set of members matching the query.
    @NSManaged var members: Set<MemberDTO>
        
    static func load(queryHash: String, context: NSManagedObjectContext) -> ChannelMemberListQueryDTO? {
        let request = NSFetchRequest<ChannelMemberListQueryDTO>(entityName: ChannelMemberListQueryDTO.entityName)
        request.predicate = NSPredicate(format: "queryHash == %@", queryHash)
        return try? context.fetch(request).first
    }
    
    static func loadOrCreate(queryHash: String, context: NSManagedObjectContext) -> ChannelMemberListQueryDTO {
        if let existing = Self.load(queryHash: queryHash, context: context) {
            return existing
        }
        
        let new = ChannelMemberListQueryDTO(context: context)
        new.queryHash = queryHash
        return new
    }
}

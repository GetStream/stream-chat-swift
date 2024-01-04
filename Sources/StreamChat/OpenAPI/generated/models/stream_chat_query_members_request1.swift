//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatQueryMembersRequest1: Codable, Hashable {
    public var sort: [StreamChatSortParamRequest?]?
    
    public var type: String
    
    public var filterConditions: [String: RawJSON]?
    
    public var id: String
    
    public var limit: Int?
    
    public var next: String?
    
    public var prev: String?
    
    public init(sort: [StreamChatSortParamRequest?]?, type: String, filterConditions: [String: RawJSON]?, id: String, limit: Int?, next: String?, prev: String?) {
        self.sort = sort
        
        self.type = type
        
        self.filterConditions = filterConditions
        
        self.id = id
        
        self.limit = limit
        
        self.next = next
        
        self.prev = prev
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case sort
        
        case type
        
        case filterConditions = "filter_conditions"
        
        case id
        
        case limit
        
        case next
        
        case prev
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(sort, forKey: .sort)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(filterConditions, forKey: .filterConditions)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(limit, forKey: .limit)
        
        try container.encode(next, forKey: .next)
        
        try container.encode(prev, forKey: .prev)
    }
}

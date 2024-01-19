//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatQueryMembersRequest1: Codable, Hashable {
    public var prev: String?
    
    public var sort: [StreamChatSortParamRequest?]?
    
    public var type: String
    
    public var filterConditions: [String: RawJSON]?
    
    public var id: String
    
    public var limit: Int?
    
    public var next: String?
    
    public init(prev: String?, sort: [StreamChatSortParamRequest?]?, type: String, filterConditions: [String: RawJSON]?, id: String, limit: Int?, next: String?) {
        self.prev = prev
        
        self.sort = sort
        
        self.type = type
        
        self.filterConditions = filterConditions
        
        self.id = id
        
        self.limit = limit
        
        self.next = next
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case prev
        
        case sort
        
        case type
        
        case filterConditions = "filter_conditions"
        
        case id
        
        case limit
        
        case next
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(prev, forKey: .prev)
        
        try container.encode(sort, forKey: .sort)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(filterConditions, forKey: .filterConditions)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(limit, forKey: .limit)
        
        try container.encode(next, forKey: .next)
    }
}

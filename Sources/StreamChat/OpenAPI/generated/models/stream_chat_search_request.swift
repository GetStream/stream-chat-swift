//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatSearchRequest: Codable, Hashable {
    public var filterConditions: [String: RawJSON]
    
    public var limit: Int? = nil
    
    public var next: String? = nil
    
    public var offset: Int? = nil
    
    public var query: String? = nil
    
    public var sort: [StreamChatSortParam?]? = nil
    
    public var messageFilterConditions: [String: RawJSON]? = nil
    
    public init(filterConditions: [String: RawJSON], limit: Int? = nil, next: String? = nil, offset: Int? = nil, query: String? = nil, sort: [StreamChatSortParam?]? = nil, messageFilterConditions: [String: RawJSON]? = nil) {
        self.filterConditions = filterConditions
        
        self.limit = limit
        
        self.next = next
        
        self.offset = offset
        
        self.query = query
        
        self.sort = sort
        
        self.messageFilterConditions = messageFilterConditions
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case filterConditions = "filter_conditions"
        
        case limit
        
        case next
        
        case offset
        
        case query
        
        case sort
        
        case messageFilterConditions = "message_filter_conditions"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(filterConditions, forKey: .filterConditions)
        
        try container.encode(limit, forKey: .limit)
        
        try container.encode(next, forKey: .next)
        
        try container.encode(offset, forKey: .offset)
        
        try container.encode(query, forKey: .query)
        
        try container.encode(sort, forKey: .sort)
        
        try container.encode(messageFilterConditions, forKey: .messageFilterConditions)
    }
}

//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatSearchRequest: Codable, Hashable {
    public var limit: Int?
    
    public var messageFilterConditions: [String: RawJSON]?
    
    public var next: String?
    
    public var offset: Int?
    
    public var query: String?
    
    public var sort: [StreamChatSortParam?]?
    
    public var filterConditions: [String: RawJSON]
    
    public init(limit: Int?, messageFilterConditions: [String: RawJSON]?, next: String?, offset: Int?, query: String?, sort: [StreamChatSortParam?]?, filterConditions: [String: RawJSON]) {
        self.limit = limit
        
        self.messageFilterConditions = messageFilterConditions
        
        self.next = next
        
        self.offset = offset
        
        self.query = query
        
        self.sort = sort
        
        self.filterConditions = filterConditions
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case limit
        
        case messageFilterConditions = "message_filter_conditions"
        
        case next
        
        case offset
        
        case query
        
        case sort
        
        case filterConditions = "filter_conditions"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(limit, forKey: .limit)
        
        try container.encode(messageFilterConditions, forKey: .messageFilterConditions)
        
        try container.encode(next, forKey: .next)
        
        try container.encode(offset, forKey: .offset)
        
        try container.encode(query, forKey: .query)
        
        try container.encode(sort, forKey: .sort)
        
        try container.encode(filterConditions, forKey: .filterConditions)
    }
}

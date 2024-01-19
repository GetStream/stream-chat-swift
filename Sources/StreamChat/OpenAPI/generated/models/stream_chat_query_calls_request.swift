//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatQueryCallsRequest: Codable, Hashable {
    public var filterConditions: [String: RawJSON]?
    
    public var limit: Int?
    
    public var next: String?
    
    public var prev: String?
    
    public var sort: [StreamChatSortParamRequest?]?
    
    public var watch: Bool?
    
    public init(filterConditions: [String: RawJSON]?, limit: Int?, next: String?, prev: String?, sort: [StreamChatSortParamRequest?]?, watch: Bool?) {
        self.filterConditions = filterConditions
        
        self.limit = limit
        
        self.next = next
        
        self.prev = prev
        
        self.sort = sort
        
        self.watch = watch
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case filterConditions = "filter_conditions"
        
        case limit
        
        case next
        
        case prev
        
        case sort
        
        case watch
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(filterConditions, forKey: .filterConditions)
        
        try container.encode(limit, forKey: .limit)
        
        try container.encode(next, forKey: .next)
        
        try container.encode(prev, forKey: .prev)
        
        try container.encode(sort, forKey: .sort)
        
        try container.encode(watch, forKey: .watch)
    }
}

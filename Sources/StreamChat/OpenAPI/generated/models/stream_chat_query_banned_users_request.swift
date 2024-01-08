//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatQueryBannedUsersRequest: Codable, Hashable {
    public var createdAtAfter: String?
    
    public var createdAtBeforeOrEqual: String?
    
    public var filterConditions: [String: RawJSON]
    
    public var offset: Int?
    
    public var user: StreamChatUserObject?
    
    public var createdAtAfterOrEqual: String?
    
    public var createdAtBefore: String?
    
    public var excludeExpiredBans: Bool?
    
    public var limit: Int?
    
    public var sort: [StreamChatSortParam?]?
    
    public var userId: String?
    
    public init(createdAtAfter: String?, createdAtBeforeOrEqual: String?, filterConditions: [String: RawJSON], offset: Int?, user: StreamChatUserObject?, createdAtAfterOrEqual: String?, createdAtBefore: String?, excludeExpiredBans: Bool?, limit: Int?, sort: [StreamChatSortParam?]?, userId: String?) {
        self.createdAtAfter = createdAtAfter
        
        self.createdAtBeforeOrEqual = createdAtBeforeOrEqual
        
        self.filterConditions = filterConditions
        
        self.offset = offset
        
        self.user = user
        
        self.createdAtAfterOrEqual = createdAtAfterOrEqual
        
        self.createdAtBefore = createdAtBefore
        
        self.excludeExpiredBans = excludeExpiredBans
        
        self.limit = limit
        
        self.sort = sort
        
        self.userId = userId
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAtAfter = "created_at_after"
        
        case createdAtBeforeOrEqual = "created_at_before_or_equal"
        
        case filterConditions = "filter_conditions"
        
        case offset
        
        case user
        
        case createdAtAfterOrEqual = "created_at_after_or_equal"
        
        case createdAtBefore = "created_at_before"
        
        case excludeExpiredBans = "exclude_expired_bans"
        
        case limit
        
        case sort
        
        case userId = "user_id"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(createdAtAfter, forKey: .createdAtAfter)
        
        try container.encode(createdAtBeforeOrEqual, forKey: .createdAtBeforeOrEqual)
        
        try container.encode(filterConditions, forKey: .filterConditions)
        
        try container.encode(offset, forKey: .offset)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(createdAtAfterOrEqual, forKey: .createdAtAfterOrEqual)
        
        try container.encode(createdAtBefore, forKey: .createdAtBefore)
        
        try container.encode(excludeExpiredBans, forKey: .excludeExpiredBans)
        
        try container.encode(limit, forKey: .limit)
        
        try container.encode(sort, forKey: .sort)
        
        try container.encode(userId, forKey: .userId)
    }
}

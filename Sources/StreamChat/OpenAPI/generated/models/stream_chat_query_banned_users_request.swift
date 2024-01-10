//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatQueryBannedUsersRequest: Codable, Hashable {
    public var userId: String?
    
    public var createdAtAfter: String?
    
    public var createdAtAfterOrEqual: String?
    
    public var createdAtBefore: String?
    
    public var user: StreamChatUserObject?
    
    public var offset: Int?
    
    public var sort: [StreamChatSortParam?]?
    
    public var createdAtBeforeOrEqual: String?
    
    public var excludeExpiredBans: Bool?
    
    public var filterConditions: [String: RawJSON]
    
    public var limit: Int?
    
    public init(userId: String?, createdAtAfter: String?, createdAtAfterOrEqual: String?, createdAtBefore: String?, user: StreamChatUserObject?, offset: Int?, sort: [StreamChatSortParam?]?, createdAtBeforeOrEqual: String?, excludeExpiredBans: Bool?, filterConditions: [String: RawJSON], limit: Int?) {
        self.userId = userId
        
        self.createdAtAfter = createdAtAfter
        
        self.createdAtAfterOrEqual = createdAtAfterOrEqual
        
        self.createdAtBefore = createdAtBefore
        
        self.user = user
        
        self.offset = offset
        
        self.sort = sort
        
        self.createdAtBeforeOrEqual = createdAtBeforeOrEqual
        
        self.excludeExpiredBans = excludeExpiredBans
        
        self.filterConditions = filterConditions
        
        self.limit = limit
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case userId = "user_id"
        
        case createdAtAfter = "created_at_after"
        
        case createdAtAfterOrEqual = "created_at_after_or_equal"
        
        case createdAtBefore = "created_at_before"
        
        case user
        
        case offset
        
        case sort
        
        case createdAtBeforeOrEqual = "created_at_before_or_equal"
        
        case excludeExpiredBans = "exclude_expired_bans"
        
        case filterConditions = "filter_conditions"
        
        case limit
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(userId, forKey: .userId)
        
        try container.encode(createdAtAfter, forKey: .createdAtAfter)
        
        try container.encode(createdAtAfterOrEqual, forKey: .createdAtAfterOrEqual)
        
        try container.encode(createdAtBefore, forKey: .createdAtBefore)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(offset, forKey: .offset)
        
        try container.encode(sort, forKey: .sort)
        
        try container.encode(createdAtBeforeOrEqual, forKey: .createdAtBeforeOrEqual)
        
        try container.encode(excludeExpiredBans, forKey: .excludeExpiredBans)
        
        try container.encode(filterConditions, forKey: .filterConditions)
        
        try container.encode(limit, forKey: .limit)
    }
}

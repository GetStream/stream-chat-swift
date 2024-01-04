//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatQueryBannedUsersRequest: Codable, Hashable {
    public var createdAtAfter: String?
    
    public var createdAtAfterOrEqual: String?
    
    public var createdAtBeforeOrEqual: String?
    
    public var sort: [StreamChatSortParam?]?
    
    public var user: StreamChatUserObject?
    
    public var createdAtBefore: String?
    
    public var excludeExpiredBans: Bool?
    
    public var filterConditions: [String: RawJSON]
    
    public var limit: Int?
    
    public var offset: Int?
    
    public var userId: String?
    
    public init(createdAtAfter: String?, createdAtAfterOrEqual: String?, createdAtBeforeOrEqual: String?, sort: [StreamChatSortParam?]?, user: StreamChatUserObject?, createdAtBefore: String?, excludeExpiredBans: Bool?, filterConditions: [String: RawJSON], limit: Int?, offset: Int?, userId: String?) {
        self.createdAtAfter = createdAtAfter
        
        self.createdAtAfterOrEqual = createdAtAfterOrEqual
        
        self.createdAtBeforeOrEqual = createdAtBeforeOrEqual
        
        self.sort = sort
        
        self.user = user
        
        self.createdAtBefore = createdAtBefore
        
        self.excludeExpiredBans = excludeExpiredBans
        
        self.filterConditions = filterConditions
        
        self.limit = limit
        
        self.offset = offset
        
        self.userId = userId
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAtAfter = "created_at_after"
        
        case createdAtAfterOrEqual = "created_at_after_or_equal"
        
        case createdAtBeforeOrEqual = "created_at_before_or_equal"
        
        case sort
        
        case user
        
        case createdAtBefore = "created_at_before"
        
        case excludeExpiredBans = "exclude_expired_bans"
        
        case filterConditions = "filter_conditions"
        
        case limit
        
        case offset
        
        case userId = "user_id"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(createdAtAfter, forKey: .createdAtAfter)
        
        try container.encode(createdAtAfterOrEqual, forKey: .createdAtAfterOrEqual)
        
        try container.encode(createdAtBeforeOrEqual, forKey: .createdAtBeforeOrEqual)
        
        try container.encode(sort, forKey: .sort)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(createdAtBefore, forKey: .createdAtBefore)
        
        try container.encode(excludeExpiredBans, forKey: .excludeExpiredBans)
        
        try container.encode(filterConditions, forKey: .filterConditions)
        
        try container.encode(limit, forKey: .limit)
        
        try container.encode(offset, forKey: .offset)
        
        try container.encode(userId, forKey: .userId)
    }
}

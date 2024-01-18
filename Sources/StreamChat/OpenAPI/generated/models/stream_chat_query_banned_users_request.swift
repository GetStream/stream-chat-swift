//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatQueryBannedUsersRequest: Codable, Hashable {
    public var limit: Int?
    
    public var createdAtAfter: Date?
    
    public var filterConditions: [String: RawJSON]
    
    public var createdAtBeforeOrEqual: Date?
    
    public var excludeExpiredBans: Bool?
    
    public var offset: Int?
    
    public var sort: [StreamChatSortParam?]?
    
    public var user: StreamChatUserObject?
    
    public var userId: String?
    
    public var createdAtAfterOrEqual: Date?
    
    public var createdAtBefore: Date?
    
    public init(limit: Int?, createdAtAfter: Date?, filterConditions: [String: RawJSON], createdAtBeforeOrEqual: Date?, excludeExpiredBans: Bool?, offset: Int?, sort: [StreamChatSortParam?]?, user: StreamChatUserObject?, userId: String?, createdAtAfterOrEqual: Date?, createdAtBefore: Date?) {
        self.limit = limit
        
        self.createdAtAfter = createdAtAfter
        
        self.filterConditions = filterConditions
        
        self.createdAtBeforeOrEqual = createdAtBeforeOrEqual
        
        self.excludeExpiredBans = excludeExpiredBans
        
        self.offset = offset
        
        self.sort = sort
        
        self.user = user
        
        self.userId = userId
        
        self.createdAtAfterOrEqual = createdAtAfterOrEqual
        
        self.createdAtBefore = createdAtBefore
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case limit
        
        case createdAtAfter = "created_at_after"
        
        case filterConditions = "filter_conditions"
        
        case createdAtBeforeOrEqual = "created_at_before_or_equal"
        
        case excludeExpiredBans = "exclude_expired_bans"
        
        case offset
        
        case sort
        
        case user
        
        case userId = "user_id"
        
        case createdAtAfterOrEqual = "created_at_after_or_equal"
        
        case createdAtBefore = "created_at_before"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(limit, forKey: .limit)
        
        try container.encode(createdAtAfter, forKey: .createdAtAfter)
        
        try container.encode(filterConditions, forKey: .filterConditions)
        
        try container.encode(createdAtBeforeOrEqual, forKey: .createdAtBeforeOrEqual)
        
        try container.encode(excludeExpiredBans, forKey: .excludeExpiredBans)
        
        try container.encode(offset, forKey: .offset)
        
        try container.encode(sort, forKey: .sort)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(userId, forKey: .userId)
        
        try container.encode(createdAtAfterOrEqual, forKey: .createdAtAfterOrEqual)
        
        try container.encode(createdAtBefore, forKey: .createdAtBefore)
    }
}

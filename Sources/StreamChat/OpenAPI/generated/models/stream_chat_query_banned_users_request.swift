//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatQueryBannedUsersRequest: Codable, Hashable {
    public var userId: String?
    
    public var createdAtAfterOrEqual: Date?
    
    public var createdAtBefore: Date?
    
    public var createdAtBeforeOrEqual: Date?
    
    public var excludeExpiredBans: Bool?
    
    public var filterConditions: [String: RawJSON]
    
    public var sort: [StreamChatSortParam?]?
    
    public var user: StreamChatUserObject?
    
    public var createdAtAfter: Date?
    
    public var limit: Int?
    
    public var offset: Int?
    
    public init(userId: String?, createdAtAfterOrEqual: Date?, createdAtBefore: Date?, createdAtBeforeOrEqual: Date?, excludeExpiredBans: Bool?, filterConditions: [String: RawJSON], sort: [StreamChatSortParam?]?, user: StreamChatUserObject?, createdAtAfter: Date?, limit: Int?, offset: Int?) {
        self.userId = userId
        
        self.createdAtAfterOrEqual = createdAtAfterOrEqual
        
        self.createdAtBefore = createdAtBefore
        
        self.createdAtBeforeOrEqual = createdAtBeforeOrEqual
        
        self.excludeExpiredBans = excludeExpiredBans
        
        self.filterConditions = filterConditions
        
        self.sort = sort
        
        self.user = user
        
        self.createdAtAfter = createdAtAfter
        
        self.limit = limit
        
        self.offset = offset
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case userId = "user_id"
        
        case createdAtAfterOrEqual = "created_at_after_or_equal"
        
        case createdAtBefore = "created_at_before"
        
        case createdAtBeforeOrEqual = "created_at_before_or_equal"
        
        case excludeExpiredBans = "exclude_expired_bans"
        
        case filterConditions = "filter_conditions"
        
        case sort
        
        case user
        
        case createdAtAfter = "created_at_after"
        
        case limit
        
        case offset
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(userId, forKey: .userId)
        
        try container.encode(createdAtAfterOrEqual, forKey: .createdAtAfterOrEqual)
        
        try container.encode(createdAtBefore, forKey: .createdAtBefore)
        
        try container.encode(createdAtBeforeOrEqual, forKey: .createdAtBeforeOrEqual)
        
        try container.encode(excludeExpiredBans, forKey: .excludeExpiredBans)
        
        try container.encode(filterConditions, forKey: .filterConditions)
        
        try container.encode(sort, forKey: .sort)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(createdAtAfter, forKey: .createdAtAfter)
        
        try container.encode(limit, forKey: .limit)
        
        try container.encode(offset, forKey: .offset)
    }
}

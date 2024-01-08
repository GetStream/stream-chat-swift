//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatQueryMembersRequest: Codable, Hashable {
    public var createdAtBeforeOrEqual: String?
    
    public var members: [StreamChatChannelMember?]?
    
    public var sort: [StreamChatSortParam?]?
    
    public var userIdGte: String?
    
    public var createdAtAfterOrEqual: String?
    
    public var filterConditions: [String: RawJSON]
    
    public var offset: Int?
    
    public var user: StreamChatUserObject?
    
    public var userIdLt: String?
    
    public var id: String?
    
    public var limit: Int?
    
    public var type: String
    
    public var userId: String?
    
    public var userIdGt: String?
    
    public var userIdLte: String?
    
    public var createdAtAfter: String?
    
    public var createdAtBefore: String?
    
    public init(createdAtBeforeOrEqual: String?, members: [StreamChatChannelMember?]?, sort: [StreamChatSortParam?]?, userIdGte: String?, createdAtAfterOrEqual: String?, filterConditions: [String: RawJSON], offset: Int?, user: StreamChatUserObject?, userIdLt: String?, id: String?, limit: Int?, type: String, userId: String?, userIdGt: String?, userIdLte: String?, createdAtAfter: String?, createdAtBefore: String?) {
        self.createdAtBeforeOrEqual = createdAtBeforeOrEqual
        
        self.members = members
        
        self.sort = sort
        
        self.userIdGte = userIdGte
        
        self.createdAtAfterOrEqual = createdAtAfterOrEqual
        
        self.filterConditions = filterConditions
        
        self.offset = offset
        
        self.user = user
        
        self.userIdLt = userIdLt
        
        self.id = id
        
        self.limit = limit
        
        self.type = type
        
        self.userId = userId
        
        self.userIdGt = userIdGt
        
        self.userIdLte = userIdLte
        
        self.createdAtAfter = createdAtAfter
        
        self.createdAtBefore = createdAtBefore
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAtBeforeOrEqual = "created_at_before_or_equal"
        
        case members
        
        case sort
        
        case userIdGte = "user_id_gte"
        
        case createdAtAfterOrEqual = "created_at_after_or_equal"
        
        case filterConditions = "filter_conditions"
        
        case offset
        
        case user
        
        case userIdLt = "user_id_lt"
        
        case id
        
        case limit
        
        case type
        
        case userId = "user_id"
        
        case userIdGt = "user_id_gt"
        
        case userIdLte = "user_id_lte"
        
        case createdAtAfter = "created_at_after"
        
        case createdAtBefore = "created_at_before"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(createdAtBeforeOrEqual, forKey: .createdAtBeforeOrEqual)
        
        try container.encode(members, forKey: .members)
        
        try container.encode(sort, forKey: .sort)
        
        try container.encode(userIdGte, forKey: .userIdGte)
        
        try container.encode(createdAtAfterOrEqual, forKey: .createdAtAfterOrEqual)
        
        try container.encode(filterConditions, forKey: .filterConditions)
        
        try container.encode(offset, forKey: .offset)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(userIdLt, forKey: .userIdLt)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(limit, forKey: .limit)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(userId, forKey: .userId)
        
        try container.encode(userIdGt, forKey: .userIdGt)
        
        try container.encode(userIdLte, forKey: .userIdLte)
        
        try container.encode(createdAtAfter, forKey: .createdAtAfter)
        
        try container.encode(createdAtBefore, forKey: .createdAtBefore)
    }
}

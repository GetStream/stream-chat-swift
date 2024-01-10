//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatQueryMembersRequest: Codable, Hashable {
    public var createdAtAfter: String?
    
    public var user: StreamChatUserObject?
    
    public var filterConditions: [String: RawJSON]
    
    public var id: String?
    
    public var members: [StreamChatChannelMember?]?
    
    public var userIdLt: String?
    
    public var userIdLte: String?
    
    public var createdAtAfterOrEqual: String?
    
    public var createdAtBeforeOrEqual: String?
    
    public var limit: Int?
    
    public var sort: [StreamChatSortParam?]?
    
    public var type: String
    
    public var createdAtBefore: String?
    
    public var offset: Int?
    
    public var userId: String?
    
    public var userIdGt: String?
    
    public var userIdGte: String?
    
    public init(createdAtAfter: String?, user: StreamChatUserObject?, filterConditions: [String: RawJSON], id: String?, members: [StreamChatChannelMember?]?, userIdLt: String?, userIdLte: String?, createdAtAfterOrEqual: String?, createdAtBeforeOrEqual: String?, limit: Int?, sort: [StreamChatSortParam?]?, type: String, createdAtBefore: String?, offset: Int?, userId: String?, userIdGt: String?, userIdGte: String?) {
        self.createdAtAfter = createdAtAfter
        
        self.user = user
        
        self.filterConditions = filterConditions
        
        self.id = id
        
        self.members = members
        
        self.userIdLt = userIdLt
        
        self.userIdLte = userIdLte
        
        self.createdAtAfterOrEqual = createdAtAfterOrEqual
        
        self.createdAtBeforeOrEqual = createdAtBeforeOrEqual
        
        self.limit = limit
        
        self.sort = sort
        
        self.type = type
        
        self.createdAtBefore = createdAtBefore
        
        self.offset = offset
        
        self.userId = userId
        
        self.userIdGt = userIdGt
        
        self.userIdGte = userIdGte
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAtAfter = "created_at_after"
        
        case user
        
        case filterConditions = "filter_conditions"
        
        case id
        
        case members
        
        case userIdLt = "user_id_lt"
        
        case userIdLte = "user_id_lte"
        
        case createdAtAfterOrEqual = "created_at_after_or_equal"
        
        case createdAtBeforeOrEqual = "created_at_before_or_equal"
        
        case limit
        
        case sort
        
        case type
        
        case createdAtBefore = "created_at_before"
        
        case offset
        
        case userId = "user_id"
        
        case userIdGt = "user_id_gt"
        
        case userIdGte = "user_id_gte"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(createdAtAfter, forKey: .createdAtAfter)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(filterConditions, forKey: .filterConditions)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(members, forKey: .members)
        
        try container.encode(userIdLt, forKey: .userIdLt)
        
        try container.encode(userIdLte, forKey: .userIdLte)
        
        try container.encode(createdAtAfterOrEqual, forKey: .createdAtAfterOrEqual)
        
        try container.encode(createdAtBeforeOrEqual, forKey: .createdAtBeforeOrEqual)
        
        try container.encode(limit, forKey: .limit)
        
        try container.encode(sort, forKey: .sort)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(createdAtBefore, forKey: .createdAtBefore)
        
        try container.encode(offset, forKey: .offset)
        
        try container.encode(userId, forKey: .userId)
        
        try container.encode(userIdGt, forKey: .userIdGt)
        
        try container.encode(userIdGte, forKey: .userIdGte)
    }
}

//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatQueryMembersRequest: Codable, Hashable {
    public var createdAtAfterOrEqual: String?
    
    public var createdAtBefore: String?
    
    public var filterConditions: [String: RawJSON]
    
    public var limit: Int?
    
    public var members: [StreamChatChannelMember?]?
    
    public var type: String
    
    public var user: StreamChatUserObject?
    
    public var userIdLt: String?
    
    public var createdAtAfter: String?
    
    public var createdAtBeforeOrEqual: String?
    
    public var sort: [StreamChatSortParam?]?
    
    public var userIdLte: String?
    
    public var id: String?
    
    public var offset: Int?
    
    public var userId: String?
    
    public var userIdGt: String?
    
    public var userIdGte: String?
    
    public init(createdAtAfterOrEqual: String?, createdAtBefore: String?, filterConditions: [String: RawJSON], limit: Int?, members: [StreamChatChannelMember?]?, type: String, user: StreamChatUserObject?, userIdLt: String?, createdAtAfter: String?, createdAtBeforeOrEqual: String?, sort: [StreamChatSortParam?]?, userIdLte: String?, id: String?, offset: Int?, userId: String?, userIdGt: String?, userIdGte: String?) {
        self.createdAtAfterOrEqual = createdAtAfterOrEqual
        
        self.createdAtBefore = createdAtBefore
        
        self.filterConditions = filterConditions
        
        self.limit = limit
        
        self.members = members
        
        self.type = type
        
        self.user = user
        
        self.userIdLt = userIdLt
        
        self.createdAtAfter = createdAtAfter
        
        self.createdAtBeforeOrEqual = createdAtBeforeOrEqual
        
        self.sort = sort
        
        self.userIdLte = userIdLte
        
        self.id = id
        
        self.offset = offset
        
        self.userId = userId
        
        self.userIdGt = userIdGt
        
        self.userIdGte = userIdGte
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAtAfterOrEqual = "created_at_after_or_equal"
        
        case createdAtBefore = "created_at_before"
        
        case filterConditions = "filter_conditions"
        
        case limit
        
        case members
        
        case type
        
        case user
        
        case userIdLt = "user_id_lt"
        
        case createdAtAfter = "created_at_after"
        
        case createdAtBeforeOrEqual = "created_at_before_or_equal"
        
        case sort
        
        case userIdLte = "user_id_lte"
        
        case id
        
        case offset
        
        case userId = "user_id"
        
        case userIdGt = "user_id_gt"
        
        case userIdGte = "user_id_gte"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(createdAtAfterOrEqual, forKey: .createdAtAfterOrEqual)
        
        try container.encode(createdAtBefore, forKey: .createdAtBefore)
        
        try container.encode(filterConditions, forKey: .filterConditions)
        
        try container.encode(limit, forKey: .limit)
        
        try container.encode(members, forKey: .members)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(userIdLt, forKey: .userIdLt)
        
        try container.encode(createdAtAfter, forKey: .createdAtAfter)
        
        try container.encode(createdAtBeforeOrEqual, forKey: .createdAtBeforeOrEqual)
        
        try container.encode(sort, forKey: .sort)
        
        try container.encode(userIdLte, forKey: .userIdLte)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(offset, forKey: .offset)
        
        try container.encode(userId, forKey: .userId)
        
        try container.encode(userIdGt, forKey: .userIdGt)
        
        try container.encode(userIdGte, forKey: .userIdGte)
    }
}

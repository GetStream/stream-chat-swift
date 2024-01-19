//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatQueryMembersRequest: Codable, Hashable {
    public var createdAtAfter: Date?
    
    public var sort: [StreamChatSortParam?]?
    
    public var userId: String?
    
    public var userIdGte: String?
    
    public var userIdLte: String?
    
    public var createdAtAfterOrEqual: Date?
    
    public var createdAtBefore: Date?
    
    public var filterConditions: [String: RawJSON]
    
    public var id: String?
    
    public var offset: Int?
    
    public var limit: Int?
    
    public var type: String
    
    public var user: StreamChatUserObject?
    
    public var createdAtBeforeOrEqual: Date?
    
    public var members: [StreamChatChannelMember?]?
    
    public var userIdGt: String?
    
    public var userIdLt: String?
    
    public init(createdAtAfter: Date?, sort: [StreamChatSortParam?]?, userId: String?, userIdGte: String?, userIdLte: String?, createdAtAfterOrEqual: Date?, createdAtBefore: Date?, filterConditions: [String: RawJSON], id: String?, offset: Int?, limit: Int?, type: String, user: StreamChatUserObject?, createdAtBeforeOrEqual: Date?, members: [StreamChatChannelMember?]?, userIdGt: String?, userIdLt: String?) {
        self.createdAtAfter = createdAtAfter
        
        self.sort = sort
        
        self.userId = userId
        
        self.userIdGte = userIdGte
        
        self.userIdLte = userIdLte
        
        self.createdAtAfterOrEqual = createdAtAfterOrEqual
        
        self.createdAtBefore = createdAtBefore
        
        self.filterConditions = filterConditions
        
        self.id = id
        
        self.offset = offset
        
        self.limit = limit
        
        self.type = type
        
        self.user = user
        
        self.createdAtBeforeOrEqual = createdAtBeforeOrEqual
        
        self.members = members
        
        self.userIdGt = userIdGt
        
        self.userIdLt = userIdLt
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAtAfter = "created_at_after"
        
        case sort
        
        case userId = "user_id"
        
        case userIdGte = "user_id_gte"
        
        case userIdLte = "user_id_lte"
        
        case createdAtAfterOrEqual = "created_at_after_or_equal"
        
        case createdAtBefore = "created_at_before"
        
        case filterConditions = "filter_conditions"
        
        case id
        
        case offset
        
        case limit
        
        case type
        
        case user
        
        case createdAtBeforeOrEqual = "created_at_before_or_equal"
        
        case members
        
        case userIdGt = "user_id_gt"
        
        case userIdLt = "user_id_lt"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(createdAtAfter, forKey: .createdAtAfter)
        
        try container.encode(sort, forKey: .sort)
        
        try container.encode(userId, forKey: .userId)
        
        try container.encode(userIdGte, forKey: .userIdGte)
        
        try container.encode(userIdLte, forKey: .userIdLte)
        
        try container.encode(createdAtAfterOrEqual, forKey: .createdAtAfterOrEqual)
        
        try container.encode(createdAtBefore, forKey: .createdAtBefore)
        
        try container.encode(filterConditions, forKey: .filterConditions)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(offset, forKey: .offset)
        
        try container.encode(limit, forKey: .limit)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(createdAtBeforeOrEqual, forKey: .createdAtBeforeOrEqual)
        
        try container.encode(members, forKey: .members)
        
        try container.encode(userIdGt, forKey: .userIdGt)
        
        try container.encode(userIdLt, forKey: .userIdLt)
    }
}

//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatQueryMembersRequest: Codable, Hashable {
    public var createdAtAfter: Date?
    
    public var limit: Int?
    
    public var members: [StreamChatChannelMember?]?
    
    public var type: String
    
    public var userIdGte: String?
    
    public var userIdLt: String?
    
    public var createdAtBefore: Date?
    
    public var sort: [StreamChatSortParam?]?
    
    public var createdAtAfterOrEqual: Date?
    
    public var createdAtBeforeOrEqual: Date?
    
    public var offset: Int?
    
    public var userIdGt: String?
    
    public var userIdLte: String?
    
    public var filterConditions: [String: RawJSON]
    
    public var id: String?
    
    public var user: StreamChatUserObject?
    
    public var userId: String?
    
    public init(createdAtAfter: Date?, limit: Int?, members: [StreamChatChannelMember?]?, type: String, userIdGte: String?, userIdLt: String?, createdAtBefore: Date?, sort: [StreamChatSortParam?]?, createdAtAfterOrEqual: Date?, createdAtBeforeOrEqual: Date?, offset: Int?, userIdGt: String?, userIdLte: String?, filterConditions: [String: RawJSON], id: String?, user: StreamChatUserObject?, userId: String?) {
        self.createdAtAfter = createdAtAfter
        
        self.limit = limit
        
        self.members = members
        
        self.type = type
        
        self.userIdGte = userIdGte
        
        self.userIdLt = userIdLt
        
        self.createdAtBefore = createdAtBefore
        
        self.sort = sort
        
        self.createdAtAfterOrEqual = createdAtAfterOrEqual
        
        self.createdAtBeforeOrEqual = createdAtBeforeOrEqual
        
        self.offset = offset
        
        self.userIdGt = userIdGt
        
        self.userIdLte = userIdLte
        
        self.filterConditions = filterConditions
        
        self.id = id
        
        self.user = user
        
        self.userId = userId
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAtAfter = "created_at_after"
        
        case limit
        
        case members
        
        case type
        
        case userIdGte = "user_id_gte"
        
        case userIdLt = "user_id_lt"
        
        case createdAtBefore = "created_at_before"
        
        case sort
        
        case createdAtAfterOrEqual = "created_at_after_or_equal"
        
        case createdAtBeforeOrEqual = "created_at_before_or_equal"
        
        case offset
        
        case userIdGt = "user_id_gt"
        
        case userIdLte = "user_id_lte"
        
        case filterConditions = "filter_conditions"
        
        case id
        
        case user
        
        case userId = "user_id"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(createdAtAfter, forKey: .createdAtAfter)
        
        try container.encode(limit, forKey: .limit)
        
        try container.encode(members, forKey: .members)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(userIdGte, forKey: .userIdGte)
        
        try container.encode(userIdLt, forKey: .userIdLt)
        
        try container.encode(createdAtBefore, forKey: .createdAtBefore)
        
        try container.encode(sort, forKey: .sort)
        
        try container.encode(createdAtAfterOrEqual, forKey: .createdAtAfterOrEqual)
        
        try container.encode(createdAtBeforeOrEqual, forKey: .createdAtBeforeOrEqual)
        
        try container.encode(offset, forKey: .offset)
        
        try container.encode(userIdGt, forKey: .userIdGt)
        
        try container.encode(userIdLte, forKey: .userIdLte)
        
        try container.encode(filterConditions, forKey: .filterConditions)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(userId, forKey: .userId)
    }
}

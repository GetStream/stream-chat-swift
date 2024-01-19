//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatQueryChannelsRequest: Codable, Hashable {
    public var offset: Int?
    
    public var presence: Bool?
    
    public var sort: [StreamChatSortParamRequest?]?
    
    public var state: Bool?
    
    public var connectionId: String?
    
    public var limit: Int?
    
    public var memberLimit: Int?
    
    public var userId: String?
    
    public var watch: Bool?
    
    public var filterConditions: [String: RawJSON]?
    
    public var messageLimit: Int?
    
    public var user: StreamChatUserObjectRequest?
    
    public init(offset: Int?, presence: Bool?, sort: [StreamChatSortParamRequest?]?, state: Bool?, connectionId: String?, limit: Int?, memberLimit: Int?, userId: String?, watch: Bool?, filterConditions: [String: RawJSON]?, messageLimit: Int?, user: StreamChatUserObjectRequest?) {
        self.offset = offset
        
        self.presence = presence
        
        self.sort = sort
        
        self.state = state
        
        self.connectionId = connectionId
        
        self.limit = limit
        
        self.memberLimit = memberLimit
        
        self.userId = userId
        
        self.watch = watch
        
        self.filterConditions = filterConditions
        
        self.messageLimit = messageLimit
        
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case offset
        
        case presence
        
        case sort
        
        case state
        
        case connectionId = "connection_id"
        
        case limit
        
        case memberLimit = "member_limit"
        
        case userId = "user_id"
        
        case watch
        
        case filterConditions = "filter_conditions"
        
        case messageLimit = "message_limit"
        
        case user
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(offset, forKey: .offset)
        
        try container.encode(presence, forKey: .presence)
        
        try container.encode(sort, forKey: .sort)
        
        try container.encode(state, forKey: .state)
        
        try container.encode(connectionId, forKey: .connectionId)
        
        try container.encode(limit, forKey: .limit)
        
        try container.encode(memberLimit, forKey: .memberLimit)
        
        try container.encode(userId, forKey: .userId)
        
        try container.encode(watch, forKey: .watch)
        
        try container.encode(filterConditions, forKey: .filterConditions)
        
        try container.encode(messageLimit, forKey: .messageLimit)
        
        try container.encode(user, forKey: .user)
    }
}

//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatQueryChannelsRequest: Codable, Hashable {
    public var userId: String?
    
    public var filterConditions: [String: RawJSON]?
    
    public var presence: Bool?
    
    public var memberLimit: Int?
    
    public var messageLimit: Int?
    
    public var offset: Int?
    
    public var sort: [StreamChatSortParamRequest?]?
    
    public var state: Bool?
    
    public var user: StreamChatUserObjectRequest?
    
    public var connectionId: String?
    
    public var limit: Int?
    
    public var watch: Bool?
    
    public init(userId: String?, filterConditions: [String: RawJSON]?, presence: Bool?, memberLimit: Int?, messageLimit: Int?, offset: Int?, sort: [StreamChatSortParamRequest?]?, state: Bool?, user: StreamChatUserObjectRequest?, connectionId: String?, limit: Int?, watch: Bool?) {
        self.userId = userId
        
        self.filterConditions = filterConditions
        
        self.presence = presence
        
        self.memberLimit = memberLimit
        
        self.messageLimit = messageLimit
        
        self.offset = offset
        
        self.sort = sort
        
        self.state = state
        
        self.user = user
        
        self.connectionId = connectionId
        
        self.limit = limit
        
        self.watch = watch
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case userId = "user_id"
        
        case filterConditions = "filter_conditions"
        
        case presence
        
        case memberLimit = "member_limit"
        
        case messageLimit = "message_limit"
        
        case offset
        
        case sort
        
        case state
        
        case user
        
        case connectionId = "connection_id"
        
        case limit
        
        case watch
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(userId, forKey: .userId)
        
        try container.encode(filterConditions, forKey: .filterConditions)
        
        try container.encode(presence, forKey: .presence)
        
        try container.encode(memberLimit, forKey: .memberLimit)
        
        try container.encode(messageLimit, forKey: .messageLimit)
        
        try container.encode(offset, forKey: .offset)
        
        try container.encode(sort, forKey: .sort)
        
        try container.encode(state, forKey: .state)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(connectionId, forKey: .connectionId)
        
        try container.encode(limit, forKey: .limit)
        
        try container.encode(watch, forKey: .watch)
    }
}

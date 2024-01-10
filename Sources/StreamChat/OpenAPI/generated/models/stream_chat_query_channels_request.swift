//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatQueryChannelsRequest: Codable, Hashable {
    public var user: StreamChatUserObjectRequest?
    
    public var userId: String?
    
    public var watch: Bool?
    
    public var limit: Int?
    
    public var offset: Int?
    
    public var presence: Bool?
    
    public var sort: [StreamChatSortParamRequest?]?
    
    public var state: Bool?
    
    public var connectionId: String?
    
    public var filterConditions: [String: RawJSON]?
    
    public var memberLimit: Int?
    
    public var messageLimit: Int?
    
    public init(user: StreamChatUserObjectRequest?, userId: String?, watch: Bool?, limit: Int?, offset: Int?, presence: Bool?, sort: [StreamChatSortParamRequest?]?, state: Bool?, connectionId: String?, filterConditions: [String: RawJSON]?, memberLimit: Int?, messageLimit: Int?) {
        self.user = user
        
        self.userId = userId
        
        self.watch = watch
        
        self.limit = limit
        
        self.offset = offset
        
        self.presence = presence
        
        self.sort = sort
        
        self.state = state
        
        self.connectionId = connectionId
        
        self.filterConditions = filterConditions
        
        self.memberLimit = memberLimit
        
        self.messageLimit = messageLimit
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case user
        
        case userId = "user_id"
        
        case watch
        
        case limit
        
        case offset
        
        case presence
        
        case sort
        
        case state
        
        case connectionId = "connection_id"
        
        case filterConditions = "filter_conditions"
        
        case memberLimit = "member_limit"
        
        case messageLimit = "message_limit"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(userId, forKey: .userId)
        
        try container.encode(watch, forKey: .watch)
        
        try container.encode(limit, forKey: .limit)
        
        try container.encode(offset, forKey: .offset)
        
        try container.encode(presence, forKey: .presence)
        
        try container.encode(sort, forKey: .sort)
        
        try container.encode(state, forKey: .state)
        
        try container.encode(connectionId, forKey: .connectionId)
        
        try container.encode(filterConditions, forKey: .filterConditions)
        
        try container.encode(memberLimit, forKey: .memberLimit)
        
        try container.encode(messageLimit, forKey: .messageLimit)
    }
}

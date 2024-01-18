//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatQueryChannelsRequest: Codable, Hashable {
    public var sort: [StreamChatSortParamRequest?]?
    
    public var state: Bool?
    
    public var user: StreamChatUserObjectRequest?
    
    public var watch: Bool?
    
    public var connectionId: String?
    
    public var limit: Int?
    
    public var presence: Bool?
    
    public var offset: Int?
    
    public var userId: String?
    
    public var filterConditions: [String: RawJSON]?
    
    public var memberLimit: Int?
    
    public var messageLimit: Int?
    
    public init(sort: [StreamChatSortParamRequest?]?, state: Bool?, user: StreamChatUserObjectRequest?, watch: Bool?, connectionId: String?, limit: Int?, presence: Bool?, offset: Int?, userId: String?, filterConditions: [String: RawJSON]?, memberLimit: Int?, messageLimit: Int?) {
        self.sort = sort
        
        self.state = state
        
        self.user = user
        
        self.watch = watch
        
        self.connectionId = connectionId
        
        self.limit = limit
        
        self.presence = presence
        
        self.offset = offset
        
        self.userId = userId
        
        self.filterConditions = filterConditions
        
        self.memberLimit = memberLimit
        
        self.messageLimit = messageLimit
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case sort
        
        case state
        
        case user
        
        case watch
        
        case connectionId = "connection_id"
        
        case limit
        
        case presence
        
        case offset
        
        case userId = "user_id"
        
        case filterConditions = "filter_conditions"
        
        case memberLimit = "member_limit"
        
        case messageLimit = "message_limit"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(sort, forKey: .sort)
        
        try container.encode(state, forKey: .state)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(watch, forKey: .watch)
        
        try container.encode(connectionId, forKey: .connectionId)
        
        try container.encode(limit, forKey: .limit)
        
        try container.encode(presence, forKey: .presence)
        
        try container.encode(offset, forKey: .offset)
        
        try container.encode(userId, forKey: .userId)
        
        try container.encode(filterConditions, forKey: .filterConditions)
        
        try container.encode(memberLimit, forKey: .memberLimit)
        
        try container.encode(messageLimit, forKey: .messageLimit)
    }
}

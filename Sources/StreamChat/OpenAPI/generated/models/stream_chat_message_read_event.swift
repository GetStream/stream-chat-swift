//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatMessageReadEvent: Codable, Hashable {
    public var createdAt: String
    
    public var lastReadMessageId: String?
    
    public var team: String?
    
    public var type: String
    
    public var user: StreamChatUserObject?
    
    public var channelId: String
    
    public var channelType: String
    
    public var cid: String
    
    public init(createdAt: String, lastReadMessageId: String?, team: String?, type: String, user: StreamChatUserObject?, channelId: String, channelType: String, cid: String) {
        self.createdAt = createdAt
        
        self.lastReadMessageId = lastReadMessageId
        
        self.team = team
        
        self.type = type
        
        self.user = user
        
        self.channelId = channelId
        
        self.channelType = channelType
        
        self.cid = cid
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        
        case lastReadMessageId = "last_read_message_id"
        
        case team
        
        case type
        
        case user
        
        case channelId = "channel_id"
        
        case channelType = "channel_type"
        
        case cid
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(lastReadMessageId, forKey: .lastReadMessageId)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(cid, forKey: .cid)
    }
}

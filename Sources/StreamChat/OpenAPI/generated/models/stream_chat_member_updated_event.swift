//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatMemberUpdatedEvent: Codable, Hashable, Event {
    public var cid: String
    
    public var createdAt: Date
    
    public var member: StreamChatChannelMember?
    
    public var team: String?
    
    public var type: String
    
    public var user: StreamChatUserObject?
    
    public var channelId: String
    
    public var channelType: String
    
    public init(cid: String, createdAt: Date, member: StreamChatChannelMember?, team: String?, type: String, user: StreamChatUserObject?, channelId: String, channelType: String) {
        self.cid = cid
        
        self.createdAt = createdAt
        
        self.member = member
        
        self.team = team
        
        self.type = type
        
        self.user = user
        
        self.channelId = channelId
        
        self.channelType = channelType
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case cid
        
        case createdAt = "created_at"
        
        case member
        
        case team
        
        case type
        
        case user
        
        case channelId = "channel_id"
        
        case channelType = "channel_type"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(member, forKey: .member)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(channelType, forKey: .channelType)
    }
}

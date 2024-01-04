//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatMemberRemovedEvent: Codable, Hashable {
    public var channelType: String
    
    public var cid: String
    
    public var createdAt: String
    
    public var member: StreamChatChannelMember?
    
    public var type: String
    
    public var user: StreamChatUserObject?
    
    public var channelId: String
    
    public init(channelType: String, cid: String, createdAt: String, member: StreamChatChannelMember?, type: String, user: StreamChatUserObject?, channelId: String) {
        self.channelType = channelType
        
        self.cid = cid
        
        self.createdAt = createdAt
        
        self.member = member
        
        self.type = type
        
        self.user = user
        
        self.channelId = channelId
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channelType = "channel_type"
        
        case cid
        
        case createdAt = "created_at"
        
        case member
        
        case type
        
        case user
        
        case channelId = "channel_id"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(member, forKey: .member)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(channelId, forKey: .channelId)
    }
}

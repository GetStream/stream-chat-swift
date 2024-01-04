//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatNotificationInvitedEvent: Codable, Hashable {
    public var channelId: String
    
    public var channelType: String
    
    public var cid: String
    
    public var createdAt: String
    
    public var member: StreamChatChannelMember?
    
    public var type: String
    
    public var user: StreamChatUserObject?
    
    public var channel: StreamChatChannelResponse?
    
    public init(channelId: String, channelType: String, cid: String, createdAt: String, member: StreamChatChannelMember?, type: String, user: StreamChatUserObject?, channel: StreamChatChannelResponse?) {
        self.channelId = channelId
        
        self.channelType = channelType
        
        self.cid = cid
        
        self.createdAt = createdAt
        
        self.member = member
        
        self.type = type
        
        self.user = user
        
        self.channel = channel
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channelId = "channel_id"
        
        case channelType = "channel_type"
        
        case cid
        
        case createdAt = "created_at"
        
        case member
        
        case type
        
        case user
        
        case channel
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(member, forKey: .member)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(channel, forKey: .channel)
    }
}

//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatEvent: Codable, Hashable {
    public var custom: [String: RawJSON]
    
    public var automoderation: Bool?
    
    public var channel: StreamChatChannelResponse?
    
    public var me: StreamChatOwnUser?
    
    public var member: StreamChatChannelMember?
    
    public var watcherCount: Int?
    
    public var createdAt: String
    
    public var message: StreamChatMessage?
    
    public var reaction: StreamChatReaction?
    
    public var reason: String?
    
    public var type: String
    
    public var channelType: String?
    
    public var connectionId: String?
    
    public var parentId: String?
    
    public var user: StreamChatUserObject?
    
    public var userId: String?
    
    public var automoderationScores: StreamChatModerationResponse?
    
    public var channelId: String?
    
    public var cid: String?
    
    public var createdBy: StreamChatUserObject?
    
    public var team: String?
    
    public init(custom: [String: RawJSON], automoderation: Bool?, channel: StreamChatChannelResponse?, me: StreamChatOwnUser?, member: StreamChatChannelMember?, watcherCount: Int?, createdAt: String, message: StreamChatMessage?, reaction: StreamChatReaction?, reason: String?, type: String, channelType: String?, connectionId: String?, parentId: String?, user: StreamChatUserObject?, userId: String?, automoderationScores: StreamChatModerationResponse?, channelId: String?, cid: String?, createdBy: StreamChatUserObject?, team: String?) {
        self.custom = custom
        
        self.automoderation = automoderation
        
        self.channel = channel
        
        self.me = me
        
        self.member = member
        
        self.watcherCount = watcherCount
        
        self.createdAt = createdAt
        
        self.message = message
        
        self.reaction = reaction
        
        self.reason = reason
        
        self.type = type
        
        self.channelType = channelType
        
        self.connectionId = connectionId
        
        self.parentId = parentId
        
        self.user = user
        
        self.userId = userId
        
        self.automoderationScores = automoderationScores
        
        self.channelId = channelId
        
        self.cid = cid
        
        self.createdBy = createdBy
        
        self.team = team
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case custom = "Custom"
        
        case automoderation
        
        case channel
        
        case me
        
        case member
        
        case watcherCount = "watcher_count"
        
        case createdAt = "created_at"
        
        case message
        
        case reaction
        
        case reason
        
        case type
        
        case channelType = "channel_type"
        
        case connectionId = "connection_id"
        
        case parentId = "parent_id"
        
        case user
        
        case userId = "user_id"
        
        case automoderationScores = "automoderation_scores"
        
        case channelId = "channel_id"
        
        case cid
        
        case createdBy = "created_by"
        
        case team
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(automoderation, forKey: .automoderation)
        
        try container.encode(channel, forKey: .channel)
        
        try container.encode(me, forKey: .me)
        
        try container.encode(member, forKey: .member)
        
        try container.encode(watcherCount, forKey: .watcherCount)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(message, forKey: .message)
        
        try container.encode(reaction, forKey: .reaction)
        
        try container.encode(reason, forKey: .reason)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(connectionId, forKey: .connectionId)
        
        try container.encode(parentId, forKey: .parentId)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(userId, forKey: .userId)
        
        try container.encode(automoderationScores, forKey: .automoderationScores)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(createdBy, forKey: .createdBy)
        
        try container.encode(team, forKey: .team)
    }
}

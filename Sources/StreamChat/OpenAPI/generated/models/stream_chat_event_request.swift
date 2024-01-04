//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatEventRequest: Codable, Hashable {
    public var connectionId: String?
    
    public var message: StreamChatMessageRequest2?
    
    public var reaction: StreamChatReactionRequest?
    
    public var automoderation: Bool?
    
    public var channel: StreamChatChannelResponseRequest?
    
    public var channelType: String?
    
    public var parentId: String?
    
    public var team: String?
    
    public var userId: String?
    
    public var custom: [String: RawJSON]?
    
    public var createdBy: StreamChatUserObjectRequest?
    
    public var member: StreamChatChannelMemberRequest?
    
    public var user: StreamChatUserObjectRequest?
    
    public var watcherCount: Int?
    
    public var automoderationScores: StreamChatModerationResponseRequest?
    
    public var me: StreamChatOwnUserRequest?
    
    public var reason: String?
    
    public var type: String
    
    public var channelId: String?
    
    public var cid: String?
    
    public var createdAt: String?
    
    public init(connectionId: String?, message: StreamChatMessageRequest2?, reaction: StreamChatReactionRequest?, automoderation: Bool?, channel: StreamChatChannelResponseRequest?, channelType: String?, parentId: String?, team: String?, userId: String?, custom: [String: RawJSON]?, createdBy: StreamChatUserObjectRequest?, member: StreamChatChannelMemberRequest?, user: StreamChatUserObjectRequest?, watcherCount: Int?, automoderationScores: StreamChatModerationResponseRequest?, me: StreamChatOwnUserRequest?, reason: String?, type: String, channelId: String?, cid: String?, createdAt: String?) {
        self.connectionId = connectionId
        
        self.message = message
        
        self.reaction = reaction
        
        self.automoderation = automoderation
        
        self.channel = channel
        
        self.channelType = channelType
        
        self.parentId = parentId
        
        self.team = team
        
        self.userId = userId
        
        self.custom = custom
        
        self.createdBy = createdBy
        
        self.member = member
        
        self.user = user
        
        self.watcherCount = watcherCount
        
        self.automoderationScores = automoderationScores
        
        self.me = me
        
        self.reason = reason
        
        self.type = type
        
        self.channelId = channelId
        
        self.cid = cid
        
        self.createdAt = createdAt
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case connectionId = "connection_id"
        
        case message
        
        case reaction
        
        case automoderation
        
        case channel
        
        case channelType = "channel_type"
        
        case parentId = "parent_id"
        
        case team
        
        case userId = "user_id"
        
        case custom = "Custom"
        
        case createdBy = "created_by"
        
        case member
        
        case user
        
        case watcherCount = "watcher_count"
        
        case automoderationScores = "automoderation_scores"
        
        case me
        
        case reason
        
        case type
        
        case channelId = "channel_id"
        
        case cid
        
        case createdAt = "created_at"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(connectionId, forKey: .connectionId)
        
        try container.encode(message, forKey: .message)
        
        try container.encode(reaction, forKey: .reaction)
        
        try container.encode(automoderation, forKey: .automoderation)
        
        try container.encode(channel, forKey: .channel)
        
        try container.encode(channelType, forKey: .channelType)
        
        try container.encode(parentId, forKey: .parentId)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(userId, forKey: .userId)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(createdBy, forKey: .createdBy)
        
        try container.encode(member, forKey: .member)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(watcherCount, forKey: .watcherCount)
        
        try container.encode(automoderationScores, forKey: .automoderationScores)
        
        try container.encode(me, forKey: .me)
        
        try container.encode(reason, forKey: .reason)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(createdAt, forKey: .createdAt)
    }
}

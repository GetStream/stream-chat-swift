//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChatMessageTaskResponse: Codable, Hashable {
    public var messageId: String
    
    public var assignedTo: String?
    
    public var id: String
    
    public var text: String
    
    public var updatedAt: String
    
    public var userId: String
    
    public var channelId: String
    
    public var extra: [String: RawJSON]?
    
    public var evaluations: [StreamChatEvaluationResponse]
    
    public var reviewedAt: String?
    
    public var status: String
    
    public var channelName: String
    
    public var createdAt: String
    
    public var rule: StreamChatRuleResponse?
    
    public var triggers: [StreamChatTriggerResponse]?
    
    public var userName: String
    
    public var contentType: String
    
    public var reviewedBy: String?
    
    public init(messageId: String, assignedTo: String?, id: String, text: String, updatedAt: String, userId: String, channelId: String, extra: [String: RawJSON]?, evaluations: [StreamChatEvaluationResponse], reviewedAt: String?, status: String, channelName: String, createdAt: String, rule: StreamChatRuleResponse?, triggers: [StreamChatTriggerResponse]?, userName: String, contentType: String, reviewedBy: String?) {
        self.messageId = messageId
        
        self.assignedTo = assignedTo
        
        self.id = id
        
        self.text = text
        
        self.updatedAt = updatedAt
        
        self.userId = userId
        
        self.channelId = channelId
        
        self.extra = extra
        
        self.evaluations = evaluations
        
        self.reviewedAt = reviewedAt
        
        self.status = status
        
        self.channelName = channelName
        
        self.createdAt = createdAt
        
        self.rule = rule
        
        self.triggers = triggers
        
        self.userName = userName
        
        self.contentType = contentType
        
        self.reviewedBy = reviewedBy
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case messageId = "message_id"
        
        case assignedTo = "assigned_to"
        
        case id
        
        case text
        
        case updatedAt = "updated_at"
        
        case userId = "user_id"
        
        case channelId = "channel_id"
        
        case extra
        
        case evaluations
        
        case reviewedAt = "reviewed_at"
        
        case status
        
        case channelName = "channel_name"
        
        case createdAt = "created_at"
        
        case rule
        
        case triggers
        
        case userName = "user_name"
        
        case contentType = "content_type"
        
        case reviewedBy = "reviewed_by"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(messageId, forKey: .messageId)
        
        try container.encode(assignedTo, forKey: .assignedTo)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(text, forKey: .text)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(userId, forKey: .userId)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(extra, forKey: .extra)
        
        try container.encode(evaluations, forKey: .evaluations)
        
        try container.encode(reviewedAt, forKey: .reviewedAt)
        
        try container.encode(status, forKey: .status)
        
        try container.encode(channelName, forKey: .channelName)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(rule, forKey: .rule)
        
        try container.encode(triggers, forKey: .triggers)
        
        try container.encode(userName, forKey: .userName)
        
        try container.encode(contentType, forKey: .contentType)
        
        try container.encode(reviewedBy, forKey: .reviewedBy)
    }
}

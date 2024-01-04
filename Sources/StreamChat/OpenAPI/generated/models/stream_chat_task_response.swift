//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatTaskResponse: Codable, Hashable {
    public var triggers: [StreamChatTriggerResponse]?
    
    public var assignedTo: String?
    
    public var contentType: String
    
    public var createdAt: String
    
//    public var payload: StreamChat
    
    public var reviewedAt: String?
    
    public var evaluations: [StreamChatEvaluationResponse]
    
    public var rule: StreamChatRuleResponse?
    
    public var reviewedBy: String?
    
    public var status: String
    
    public var updatedAt: String
    
    public var extra: [String: RawJSON]?
    
    public var id: String
    
    public init(triggers: [StreamChatTriggerResponse]?, assignedTo: String?, contentType: String, createdAt: String, reviewedAt: String?, evaluations: [StreamChatEvaluationResponse], rule: StreamChatRuleResponse?, reviewedBy: String?, status: String, updatedAt: String, extra: [String: RawJSON]?, id: String) {
        self.triggers = triggers
        
        self.assignedTo = assignedTo
        
        self.contentType = contentType
        
        self.createdAt = createdAt
        
//        self.payload = payload
        
        self.reviewedAt = reviewedAt
        
        self.evaluations = evaluations
        
        self.rule = rule
        
        self.reviewedBy = reviewedBy
        
        self.status = status
        
        self.updatedAt = updatedAt
        
        self.extra = extra
        
        self.id = id
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case triggers
        
        case assignedTo = "assigned_to"
        
        case contentType = "content_type"
        
        case createdAt = "created_at"
        
//        case payload = "payload"
        
        case reviewedAt = "reviewed_at"
        
        case evaluations
        
        case rule
        
        case reviewedBy = "reviewed_by"
        
        case status
        
        case updatedAt = "updated_at"
        
        case extra
        
        case id
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(triggers, forKey: .triggers)
        
        try container.encode(assignedTo, forKey: .assignedTo)
        
        try container.encode(contentType, forKey: .contentType)
        
        try container.encode(createdAt, forKey: .createdAt)
        
//        try container.encode(payload, forKey: .payload)
        
        try container.encode(reviewedAt, forKey: .reviewedAt)
        
        try container.encode(evaluations, forKey: .evaluations)
        
        try container.encode(rule, forKey: .rule)
        
        try container.encode(reviewedBy, forKey: .reviewedBy)
        
        try container.encode(status, forKey: .status)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(extra, forKey: .extra)
        
        try container.encode(id, forKey: .id)
    }
}

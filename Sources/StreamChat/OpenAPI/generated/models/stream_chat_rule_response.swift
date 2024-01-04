//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatRuleResponse: Codable, Hashable {
    public var triggers: [StreamChatTriggerResponse]
    
    public var updatedAt: String
    
    public var condition: [String: RawJSON]
    
    public var createdAt: String
    
    public var evaluations: [StreamChatEvaluationResponse]
    
    public var filter: [String: RawJSON]
    
    public var id: String
    
    public init(triggers: [StreamChatTriggerResponse], updatedAt: String, condition: [String: RawJSON], createdAt: String, evaluations: [StreamChatEvaluationResponse], filter: [String: RawJSON], id: String) {
        self.triggers = triggers
        
        self.updatedAt = updatedAt
        
        self.condition = condition
        
        self.createdAt = createdAt
        
        self.evaluations = evaluations
        
        self.filter = filter
        
        self.id = id
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case triggers
        
        case updatedAt = "updated_at"
        
        case condition
        
        case createdAt = "created_at"
        
        case evaluations
        
        case filter
        
        case id
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(triggers, forKey: .triggers)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(condition, forKey: .condition)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(evaluations, forKey: .evaluations)
        
        try container.encode(filter, forKey: .filter)
        
        try container.encode(id, forKey: .id)
    }
}

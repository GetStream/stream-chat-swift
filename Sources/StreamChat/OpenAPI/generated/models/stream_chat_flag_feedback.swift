//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatFlagFeedback: Codable, Hashable {
    public var labels: [StreamChatLabel]
    
    public var messageId: String
    
    public var createdAt: Date
    
    public init(labels: [StreamChatLabel], messageId: String, createdAt: Date) {
        self.labels = labels
        
        self.messageId = messageId
        
        self.createdAt = createdAt
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case labels
        
        case messageId = "message_id"
        
        case createdAt = "created_at"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(labels, forKey: .labels)
        
        try container.encode(messageId, forKey: .messageId)
        
        try container.encode(createdAt, forKey: .createdAt)
    }
}

//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatFlagFeedback: Codable, Hashable {
    public var createdAt: String
    
    public var labels: [StreamChatLabel]
    
    public var messageId: String
    
    public init(createdAt: String, labels: [StreamChatLabel], messageId: String) {
        self.createdAt = createdAt
        
        self.labels = labels
        
        self.messageId = messageId
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        
        case labels
        
        case messageId = "message_id"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(labels, forKey: .labels)
        
        try container.encode(messageId, forKey: .messageId)
    }
}

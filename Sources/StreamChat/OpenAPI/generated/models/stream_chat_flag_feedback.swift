//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatFlagFeedback: Codable, Hashable {
    public var messageId: String
    
    public var createdAt: String
    
    public var labels: [StreamChatLabel]
    
    public init(messageId: String, createdAt: String, labels: [StreamChatLabel]) {
        self.messageId = messageId
        
        self.createdAt = createdAt
        
        self.labels = labels
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case messageId = "message_id"
        
        case createdAt = "created_at"
        
        case labels
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(messageId, forKey: .messageId)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(labels, forKey: .labels)
    }
}

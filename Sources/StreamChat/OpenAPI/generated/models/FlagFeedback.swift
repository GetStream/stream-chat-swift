//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct FlagFeedback: Codable, Hashable {
    public var createdAt: Date
    
    public var messageId: String
    
    public var labels: [Label]
    
    public init(createdAt: Date, messageId: String, labels: [Label]) {
        self.createdAt = createdAt
        
        self.messageId = messageId
        
        self.labels = labels
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        
        case messageId = "message_id"
        
        case labels
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(messageId, forKey: .messageId)
        
        try container.encode(labels, forKey: .labels)
    }
}

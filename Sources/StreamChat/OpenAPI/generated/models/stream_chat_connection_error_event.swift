//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatConnectionErrorEvent: Codable, Hashable, Event {
    public var error: StreamChatAPIError
    
    public var type: String
    
    public var connectionId: String
    
    public var createdAt: Date
    
    public init(error: StreamChatAPIError, type: String, connectionId: String, createdAt: Date) {
        self.error = error
        
        self.type = type
        
        self.connectionId = connectionId
        
        self.createdAt = createdAt
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case error
        
        case type
        
        case connectionId = "connection_id"
        
        case createdAt = "created_at"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(error, forKey: .error)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(connectionId, forKey: .connectionId)
        
        try container.encode(createdAt, forKey: .createdAt)
    }
}

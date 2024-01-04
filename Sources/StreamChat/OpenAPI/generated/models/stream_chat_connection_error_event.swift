//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatConnectionErrorEvent: Codable, Hashable {
    public var connectionId: String
    
    public var createdAt: String
    
    public var error: StreamChatAPIError
    
    public var type: String
    
    public init(connectionId: String, createdAt: String, error: StreamChatAPIError, type: String) {
        self.connectionId = connectionId
        
        self.createdAt = createdAt
        
        self.error = error
        
        self.type = type
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case connectionId = "connection_id"
        
        case createdAt = "created_at"
        
        case error
        
        case type
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(connectionId, forKey: .connectionId)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(error, forKey: .error)
        
        try container.encode(type, forKey: .type)
    }
}

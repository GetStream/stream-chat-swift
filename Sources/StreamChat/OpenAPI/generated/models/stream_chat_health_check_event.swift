//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatHealthCheckEvent: Codable, Hashable {
    public var createdAt: String
    
    public var type: String
    
    public var connectionId: String
    
    public init(createdAt: String, type: String, connectionId: String) {
        self.createdAt = createdAt
        
        self.type = type
        
        self.connectionId = connectionId
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        
        case type
        
        case connectionId = "connection_id"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(connectionId, forKey: .connectionId)
    }
}

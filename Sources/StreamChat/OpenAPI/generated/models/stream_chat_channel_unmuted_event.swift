//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelUnmutedEvent: Codable, Hashable {
    public var createdAt: String
    
    public var type: String
    
    public init(createdAt: String, type: String) {
        self.createdAt = createdAt
        
        self.type = type
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        
        case type
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(type, forKey: .type)
    }
}

//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatCommand: Codable, Hashable {
    public var name: String
    
    public var set: String
    
    public var updatedAt: String?
    
    public var args: String
    
    public var createdAt: String?
    
    public var description: String
    
    public init(name: String, set: String, updatedAt: String?, args: String, createdAt: String?, description: String) {
        self.name = name
        
        self.set = set
        
        self.updatedAt = updatedAt
        
        self.args = args
        
        self.createdAt = createdAt
        
        self.description = description
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case name
        
        case set
        
        case updatedAt = "updated_at"
        
        case args
        
        case createdAt = "created_at"
        
        case description
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(name, forKey: .name)
        
        try container.encode(set, forKey: .set)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(args, forKey: .args)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(description, forKey: .description)
    }
}

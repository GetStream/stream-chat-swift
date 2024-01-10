//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatCommand: Codable, Hashable {
    public var updatedAt: String?
    
    public var args: String
    
    public var createdAt: String?
    
    public var description: String
    
    public var name: String
    
    public var set: String
    
    public init(updatedAt: String?, args: String, createdAt: String?, description: String, name: String, set: String) {
        self.updatedAt = updatedAt
        
        self.args = args
        
        self.createdAt = createdAt
        
        self.description = description
        
        self.name = name
        
        self.set = set
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case updatedAt = "updated_at"
        
        case args
        
        case createdAt = "created_at"
        
        case description
        
        case name
        
        case set
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(args, forKey: .args)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(description, forKey: .description)
        
        try container.encode(name, forKey: .name)
        
        try container.encode(set, forKey: .set)
    }
}

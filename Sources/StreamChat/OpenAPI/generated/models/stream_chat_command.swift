//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatCommand: Codable, Hashable {
    public var createdAt: Date?
    
    public var description: String
    
    public var name: String
    
    public var set: String
    
    public var updatedAt: Date?
    
    public var args: String
    
    public init(createdAt: Date?, description: String, name: String, set: String, updatedAt: Date?, args: String) {
        self.createdAt = createdAt
        
        self.description = description
        
        self.name = name
        
        self.set = set
        
        self.updatedAt = updatedAt
        
        self.args = args
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        
        case description
        
        case name
        
        case set
        
        case updatedAt = "updated_at"
        
        case args
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(description, forKey: .description)
        
        try container.encode(name, forKey: .name)
        
        try container.encode(set, forKey: .set)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(args, forKey: .args)
    }
}

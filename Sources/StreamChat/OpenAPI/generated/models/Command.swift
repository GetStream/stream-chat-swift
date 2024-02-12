//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct Command: Codable, Hashable {
    public var args: String
    
    public var description: String
    
    public var name: String
    
    public var set: String
    
    public var createdAt: Date? = nil
    
    public var updatedAt: Date? = nil
    
    public init(args: String, description: String, name: String, set: String, createdAt: Date? = nil, updatedAt: Date? = nil) {
        self.args = args
        
        self.description = description
        
        self.name = name
        
        self.set = set
        
        self.createdAt = createdAt
        
        self.updatedAt = updatedAt
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case args
        
        case description
        
        case name
        
        case set
        
        case createdAt = "created_at"
        
        case updatedAt = "updated_at"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(args, forKey: .args)
        
        try container.encode(description, forKey: .description)
        
        try container.encode(name, forKey: .name)
        
        try container.encode(set, forKey: .set)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}

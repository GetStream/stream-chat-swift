//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatPolicy: Codable, Hashable {
    public var roles: [String]
    
    public var updatedAt: Date
    
    public var action: Int
    
    public var createdAt: Date
    
    public var name: String
    
    public var owner: Bool
    
    public var priority: Int
    
    public var resources: [String]
    
    public init(roles: [String], updatedAt: Date, action: Int, createdAt: Date, name: String, owner: Bool, priority: Int, resources: [String]) {
        self.roles = roles
        
        self.updatedAt = updatedAt
        
        self.action = action
        
        self.createdAt = createdAt
        
        self.name = name
        
        self.owner = owner
        
        self.priority = priority
        
        self.resources = resources
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case roles
        
        case updatedAt = "updated_at"
        
        case action
        
        case createdAt = "created_at"
        
        case name
        
        case owner
        
        case priority
        
        case resources
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(roles, forKey: .roles)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(action, forKey: .action)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(name, forKey: .name)
        
        try container.encode(owner, forKey: .owner)
        
        try container.encode(priority, forKey: .priority)
        
        try container.encode(resources, forKey: .resources)
    }
}

//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatOwnUserResponse: Codable, Hashable {
    public var language: String
    
    public var role: String
    
    public var teams: [String]
    
    public var updatedAt: Date
    
    public var createdAt: Date
    
    public var custom: [String: RawJSON]
    
    public var id: String
    
    public var name: String?
    
    public var deletedAt: Date?
    
    public var devices: [StreamChatDevice]
    
    public var image: String?
    
    public init(language: String, role: String, teams: [String], updatedAt: Date, createdAt: Date, custom: [String: RawJSON], id: String, name: String?, deletedAt: Date?, devices: [StreamChatDevice], image: String?) {
        self.language = language
        
        self.role = role
        
        self.teams = teams
        
        self.updatedAt = updatedAt
        
        self.createdAt = createdAt
        
        self.custom = custom
        
        self.id = id
        
        self.name = name
        
        self.deletedAt = deletedAt
        
        self.devices = devices
        
        self.image = image
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case language
        
        case role
        
        case teams
        
        case updatedAt = "updated_at"
        
        case createdAt = "created_at"
        
        case custom
        
        case id
        
        case name
        
        case deletedAt = "deleted_at"
        
        case devices
        
        case image
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(language, forKey: .language)
        
        try container.encode(role, forKey: .role)
        
        try container.encode(teams, forKey: .teams)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(name, forKey: .name)
        
        try container.encode(deletedAt, forKey: .deletedAt)
        
        try container.encode(devices, forKey: .devices)
        
        try container.encode(image, forKey: .image)
    }
}

//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatOwnUserResponse: Codable, Hashable {
    public var deletedAt: String?
    
    public var devices: [StreamChatDevice]
    
    public var id: String
    
    public var image: String?
    
    public var name: String?
    
    public var updatedAt: String
    
    public var createdAt: String
    
    public var custom: [String: RawJSON]
    
    public init(deletedAt: String?, devices: [StreamChatDevice], id: String, image: String?, name: String?, updatedAt: String, createdAt: String, custom: [String: RawJSON]) {
        self.deletedAt = deletedAt
        
        self.devices = devices
        
        self.id = id
        
        self.image = image
        
        self.name = name
        
        self.updatedAt = updatedAt
        
        self.createdAt = createdAt
        
        self.custom = custom
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case deletedAt = "deleted_at"
        
        case devices
        
        case id
        
        case image
        
        case name
        
        case updatedAt = "updated_at"
        
        case createdAt = "created_at"
        
        case custom
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(deletedAt, forKey: .deletedAt)
        
        try container.encode(devices, forKey: .devices)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(image, forKey: .image)
        
        try container.encode(name, forKey: .name)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(custom, forKey: .custom)
    }
}

//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUserRequest: Codable, Hashable {
    public var image: String?
    
    public var language: String?
    
    public var name: String?
    
    public var custom: [String: RawJSON]?
    
    public var id: String
    
    public init(image: String?, language: String?, name: String?, custom: [String: RawJSON]?, id: String) {
        self.image = image
        
        self.language = language
        
        self.name = name
        
        self.custom = custom
        
        self.id = id
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case image
        
        case language
        
        case name
        
        case custom
        
        case id
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(image, forKey: .image)
        
        try container.encode(language, forKey: .language)
        
        try container.encode(name, forKey: .name)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(id, forKey: .id)
    }
}

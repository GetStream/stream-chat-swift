//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUserRequest: Codable, Hashable {
    public var custom: [String: RawJSON]?
    
    public var id: String
    
    public var image: String?
    
    public var language: String?
    
    public var name: String?
    
    public init(custom: [String: RawJSON]?, id: String, image: String?, language: String?, name: String?) {
        self.custom = custom
        
        self.id = id
        
        self.image = image
        
        self.language = language
        
        self.name = name
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case custom
        
        case id
        
        case image
        
        case language
        
        case name
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(image, forKey: .image)
        
        try container.encode(language, forKey: .language)
        
        try container.encode(name, forKey: .name)
    }
}

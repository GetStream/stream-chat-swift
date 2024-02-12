//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct UserRequest: Codable, Hashable {
    public var id: String
    
    public var image: String? = nil
    
    public var language: String? = nil
    
    public var name: String? = nil
    
    public var custom: [String: RawJSON]? = nil
    
    public init(id: String, image: String? = nil, language: String? = nil, name: String? = nil, custom: [String: RawJSON]? = nil) {
        self.id = id
        
        self.image = image
        
        self.language = language
        
        self.name = name
        
        self.custom = custom
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case id
        
        case image
        
        case language
        
        case name
        
        case custom
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(image, forKey: .image)
        
        try container.encode(language, forKey: .language)
        
        try container.encode(name, forKey: .name)
        
        try container.encode(custom, forKey: .custom)
    }
}

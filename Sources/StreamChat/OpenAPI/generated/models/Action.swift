//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct Action: Codable, Hashable {
    public var name: String
    
    public var text: String
    
    public var type: String
    
    public var style: String? = nil
    
    public var value: String? = nil
    
    public init(name: String, text: String, type: String, style: String? = nil, value: String? = nil) {
        self.name = name
        
        self.text = text
        
        self.type = type
        
        self.style = style
        
        self.value = value
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case name
        
        case text
        
        case type
        
        case style
        
        case value
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(name, forKey: .name)
        
        try container.encode(text, forKey: .text)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(style, forKey: .style)
        
        try container.encode(value, forKey: .value)
    }
}

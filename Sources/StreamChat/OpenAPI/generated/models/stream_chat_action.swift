//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatAction: Codable, Hashable {
    public var style: String?
    
    public var text: String
    
    public var type: String
    
    public var value: String?
    
    public var name: String
    
    public init(style: String?, text: String, type: String, value: String?, name: String) {
        self.style = style
        
        self.text = text
        
        self.type = type
        
        self.value = value
        
        self.name = name
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case style
        
        case text
        
        case type
        
        case value
        
        case name
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(style, forKey: .style)
        
        try container.encode(text, forKey: .text)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(value, forKey: .value)
        
        try container.encode(name, forKey: .name)
    }
}

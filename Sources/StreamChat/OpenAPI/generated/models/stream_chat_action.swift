//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatAction: Codable, Hashable {
    public var value: String?
    
    public var name: String
    
    public var style: String?
    
    public var text: String
    
    public var type: String
    
    public init(value: String?, name: String, style: String?, text: String, type: String) {
        self.value = value
        
        self.name = name
        
        self.style = style
        
        self.text = text
        
        self.type = type
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case value
        
        case name
        
        case style
        
        case text
        
        case type
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(value, forKey: .value)
        
        try container.encode(name, forKey: .name)
        
        try container.encode(style, forKey: .style)
        
        try container.encode(text, forKey: .text)
        
        try container.encode(type, forKey: .type)
    }
}

//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatActionRequest: Codable, Hashable {
    public var name: String?
    
    public var style: String?
    
    public var text: String?
    
    public var type: String?
    
    public var value: String?
    
    public init(name: String?, style: String?, text: String?, type: String?, value: String?) {
        self.name = name
        
        self.style = style
        
        self.text = text
        
        self.type = type
        
        self.value = value
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case name
        
        case style
        
        case text
        
        case type
        
        case value
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(name, forKey: .name)
        
        try container.encode(style, forKey: .style)
        
        try container.encode(text, forKey: .text)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(value, forKey: .value)
    }
}

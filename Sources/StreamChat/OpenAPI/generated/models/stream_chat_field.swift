//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatField: Codable, Hashable {
    public var title: String
    
    public var value: String
    
    public var short: Bool
    
    public init(title: String, value: String, short: Bool) {
        self.title = title
        
        self.value = value
        
        self.short = short
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case title
        
        case value
        
        case short
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(title, forKey: .title)
        
        try container.encode(value, forKey: .value)
        
        try container.encode(short, forKey: .short)
    }
}

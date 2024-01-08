//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatThresholds: Codable, Hashable {
    public var spam: StreamChatLabelThresholds?
    
    public var toxic: StreamChatLabelThresholds?
    
    public var explicit: StreamChatLabelThresholds?
    
    public init(spam: StreamChatLabelThresholds?, toxic: StreamChatLabelThresholds?, explicit: StreamChatLabelThresholds?) {
        self.spam = spam
        
        self.toxic = toxic
        
        self.explicit = explicit
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case spam
        
        case toxic
        
        case explicit
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(spam, forKey: .spam)
        
        try container.encode(toxic, forKey: .toxic)
        
        try container.encode(explicit, forKey: .explicit)
    }
}

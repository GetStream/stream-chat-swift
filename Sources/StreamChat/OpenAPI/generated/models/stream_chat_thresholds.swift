//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatThresholds: Codable, Hashable {
    public var explicit: StreamChatLabelThresholds?
    
    public var spam: StreamChatLabelThresholds?
    
    public var toxic: StreamChatLabelThresholds?
    
    public init(explicit: StreamChatLabelThresholds?, spam: StreamChatLabelThresholds?, toxic: StreamChatLabelThresholds?) {
        self.explicit = explicit
        
        self.spam = spam
        
        self.toxic = toxic
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case explicit
        
        case spam
        
        case toxic
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(explicit, forKey: .explicit)
        
        try container.encode(spam, forKey: .spam)
        
        try container.encode(toxic, forKey: .toxic)
    }
}

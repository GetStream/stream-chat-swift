//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatThresholdsRequest: Codable, Hashable {
    public var explicit: StreamChatLabelThresholdsRequest?
    
    public var spam: StreamChatLabelThresholdsRequest?
    
    public var toxic: StreamChatLabelThresholdsRequest?
    
    public init(explicit: StreamChatLabelThresholdsRequest?, spam: StreamChatLabelThresholdsRequest?, toxic: StreamChatLabelThresholdsRequest?) {
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

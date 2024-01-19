//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatModerationResponse: Codable, Hashable {
    public var explicit: Double
    
    public var spam: Double
    
    public var toxic: Double
    
    public var action: String
    
    public init(explicit: Double, spam: Double, toxic: Double, action: String) {
        self.explicit = explicit
        
        self.spam = spam
        
        self.toxic = toxic
        
        self.action = action
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case explicit
        
        case spam
        
        case toxic
        
        case action
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(explicit, forKey: .explicit)
        
        try container.encode(spam, forKey: .spam)
        
        try container.encode(toxic, forKey: .toxic)
        
        try container.encode(action, forKey: .action)
    }
}

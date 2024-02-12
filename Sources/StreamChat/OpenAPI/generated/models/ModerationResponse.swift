//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct ModerationResponse: Codable, Hashable {
    public var action: String
    
    public var explicit: Double
    
    public var spam: Double
    
    public var toxic: Double
    
    public init(action: String, explicit: Double, spam: Double, toxic: Double) {
        self.action = action
        
        self.explicit = explicit
        
        self.spam = spam
        
        self.toxic = toxic
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case action
        
        case explicit
        
        case spam
        
        case toxic
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(action, forKey: .action)
        
        try container.encode(explicit, forKey: .explicit)
        
        try container.encode(spam, forKey: .spam)
        
        try container.encode(toxic, forKey: .toxic)
    }
}

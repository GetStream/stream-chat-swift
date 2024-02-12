//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct Thresholds: Codable, Hashable {
    public var explicit: LabelThresholds? = nil
    
    public var spam: LabelThresholds? = nil
    
    public var toxic: LabelThresholds? = nil
    
    public init(explicit: LabelThresholds? = nil, spam: LabelThresholds? = nil, toxic: LabelThresholds? = nil) {
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

//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatSyncResponse: Codable, Hashable {
    public var duration: String
    
    public var events: [StreamChatEvent?]
    
    public var inaccessibleCids: [String]?
    
    public init(duration: String, events: [StreamChatEvent?], inaccessibleCids: [String]?) {
        self.duration = duration
        
        self.events = events
        
        self.inaccessibleCids = inaccessibleCids
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        
        case events
        
        case inaccessibleCids = "inaccessible_cids"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(duration, forKey: .duration)
        
        try container.encode(events, forKey: .events)
        
        try container.encode(inaccessibleCids, forKey: .inaccessibleCids)
    }
}

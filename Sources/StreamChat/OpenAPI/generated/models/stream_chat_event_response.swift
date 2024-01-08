//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatEventResponse: Codable, Hashable {
    public var duration: String
    
    public var event: StreamChatWSEvent
    
    public init(duration: String, event: StreamChatWSEvent) {
        self.duration = duration
        
        self.event = event
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        
        case event
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(duration, forKey: .duration)
        
        try container.encode(event, forKey: .event)
    }
}

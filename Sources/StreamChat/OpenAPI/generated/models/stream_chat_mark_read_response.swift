//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatMarkReadResponse: Codable, Hashable {
    public var event: StreamChatMessageReadEvent?
    
    public var duration: String
    
    public init(event: StreamChatMessageReadEvent?, duration: String) {
        self.event = event
        
        self.duration = duration
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case event
        
        case duration
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(event, forKey: .event)
        
        try container.encode(duration, forKey: .duration)
    }
}

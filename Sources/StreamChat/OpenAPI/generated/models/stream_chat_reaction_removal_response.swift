//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatReactionRemovalResponse: Codable, Hashable {
    public var reaction: StreamChatReaction?
    
    public var duration: String
    
    public var message: StreamChatMessage?
    
    public init(reaction: StreamChatReaction?, duration: String, message: StreamChatMessage?) {
        self.reaction = reaction
        
        self.duration = duration
        
        self.message = message
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case reaction
        
        case duration
        
        case message
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(reaction, forKey: .reaction)
        
        try container.encode(duration, forKey: .duration)
        
        try container.encode(message, forKey: .message)
    }
}

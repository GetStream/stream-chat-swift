//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatReactionRemovalResponse: Codable, Hashable {
    public var duration: String
    
    public var message: StreamChatMessage? = nil
    
    public var reaction: StreamChatReaction? = nil
    
    public init(duration: String, message: StreamChatMessage? = nil, reaction: StreamChatReaction? = nil) {
        self.duration = duration
        
        self.message = message
        
        self.reaction = reaction
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        
        case message
        
        case reaction
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(duration, forKey: .duration)
        
        try container.encode(message, forKey: .message)
        
        try container.encode(reaction, forKey: .reaction)
    }
}

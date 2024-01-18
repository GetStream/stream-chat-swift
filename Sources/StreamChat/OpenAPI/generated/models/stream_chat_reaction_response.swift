//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatReactionResponse: Codable, Hashable {
    public var message: StreamChatMessage?
    
    public var reaction: StreamChatReaction?
    
    public var duration: String
    
    public init(message: StreamChatMessage?, reaction: StreamChatReaction?, duration: String) {
        self.message = message
        
        self.reaction = reaction
        
        self.duration = duration
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case message
        
        case reaction
        
        case duration
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(message, forKey: .message)
        
        try container.encode(reaction, forKey: .reaction)
        
        try container.encode(duration, forKey: .duration)
    }
}

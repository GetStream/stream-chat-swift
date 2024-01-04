//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatSendReactionResponse: Codable, Hashable {
    public var duration: String
    
    public var reaction: StreamChatReactionResponse
    
    public init(duration: String, reaction: StreamChatReactionResponse) {
        self.duration = duration
        
        self.reaction = reaction
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        
        case reaction
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(duration, forKey: .duration)
        
        try container.encode(reaction, forKey: .reaction)
    }
}

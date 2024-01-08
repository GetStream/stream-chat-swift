//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatGetReactionsResponse: Codable, Hashable {
    public var duration: String
    
    public var reactions: [StreamChatReaction?]
    
    public init(duration: String, reactions: [StreamChatReaction?]) {
        self.duration = duration
        
        self.reactions = reactions
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        
        case reactions
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(duration, forKey: .duration)
        
        try container.encode(reactions, forKey: .reactions)
    }
}

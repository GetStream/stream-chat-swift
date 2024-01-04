//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatGetRepliesResponse: Codable, Hashable {
    public var messages: [StreamChatMessage]
    
    public var duration: String
    
    public init(messages: [StreamChatMessage], duration: String) {
        self.messages = messages
        
        self.duration = duration
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case messages
        
        case duration
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(messages, forKey: .messages)
        
        try container.encode(duration, forKey: .duration)
    }
}

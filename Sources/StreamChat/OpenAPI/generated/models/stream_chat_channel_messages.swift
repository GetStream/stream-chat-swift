//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelMessages: Codable, Hashable {
    public var channel: StreamChatChannelResponse?
    
    public var messages: [StreamChatMessage]
    
    public init(channel: StreamChatChannelResponse?, messages: [StreamChatMessage]) {
        self.channel = channel
        
        self.messages = messages
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channel
        
        case messages
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(channel, forKey: .channel)
        
        try container.encode(messages, forKey: .messages)
    }
}

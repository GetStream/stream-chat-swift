//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatTruncateChannelResponse: Codable, Hashable {
    public var channel: StreamChatChannelResponse?
    
    public var duration: String
    
    public var message: StreamChatMessage?
    
    public init(channel: StreamChatChannelResponse?, duration: String, message: StreamChatMessage?) {
        self.channel = channel
        
        self.duration = duration
        
        self.message = message
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channel
        
        case duration
        
        case message
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(channel, forKey: .channel)
        
        try container.encode(duration, forKey: .duration)
        
        try container.encode(message, forKey: .message)
    }
}

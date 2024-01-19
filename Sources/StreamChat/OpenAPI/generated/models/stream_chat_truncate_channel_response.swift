//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatTruncateChannelResponse: Codable, Hashable {
    public var message: StreamChatMessage?
    
    public var channel: StreamChatChannelResponse?
    
    public var duration: String
    
    public init(message: StreamChatMessage?, channel: StreamChatChannelResponse?, duration: String) {
        self.message = message
        
        self.channel = channel
        
        self.duration = duration
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case message
        
        case channel
        
        case duration
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(message, forKey: .message)
        
        try container.encode(channel, forKey: .channel)
        
        try container.encode(duration, forKey: .duration)
    }
}

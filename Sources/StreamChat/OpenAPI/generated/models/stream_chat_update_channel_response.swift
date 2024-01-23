//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUpdateChannelResponse: Codable, Hashable {
    public var duration: String
    
    public var members: [StreamChatChannelMember?]
    
    public var channel: StreamChatChannelResponse? = nil
    
    public var message: StreamChatMessage? = nil
    
    public init(duration: String, members: [StreamChatChannelMember?], channel: StreamChatChannelResponse? = nil, message: StreamChatMessage? = nil) {
        self.duration = duration
        
        self.members = members
        
        self.channel = channel
        
        self.message = message
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        
        case members
        
        case channel
        
        case message
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(duration, forKey: .duration)
        
        try container.encode(members, forKey: .members)
        
        try container.encode(channel, forKey: .channel)
        
        try container.encode(message, forKey: .message)
    }
}

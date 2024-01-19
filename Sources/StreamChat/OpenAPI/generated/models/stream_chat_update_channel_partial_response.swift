//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUpdateChannelPartialResponse: Codable, Hashable {
    public var duration: String
    
    public var members: [StreamChatChannelMember?]
    
    public var channel: StreamChatChannelResponse?
    
    public init(duration: String, members: [StreamChatChannelMember?], channel: StreamChatChannelResponse?) {
        self.duration = duration
        
        self.members = members
        
        self.channel = channel
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        
        case members
        
        case channel
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(duration, forKey: .duration)
        
        try container.encode(members, forKey: .members)
        
        try container.encode(channel, forKey: .channel)
    }
}

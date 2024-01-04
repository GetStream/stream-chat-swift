//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatDeleteChannelResponse: Codable, Hashable {
    public var channel: StreamChatChannelResponse?
    
    public var duration: String
    
    public init(channel: StreamChatChannelResponse?, duration: String) {
        self.channel = channel
        
        self.duration = duration
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channel
        
        case duration
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(channel, forKey: .channel)
        
        try container.encode(duration, forKey: .duration)
    }
}

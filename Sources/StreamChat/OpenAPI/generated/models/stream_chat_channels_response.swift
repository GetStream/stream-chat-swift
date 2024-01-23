//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelsResponse: Codable, Hashable {
    public var duration: String
    
    public var channels: [StreamChatChannelStateResponseFields]
    
    public init(duration: String, channels: [StreamChatChannelStateResponseFields]) {
        self.duration = duration
        
        self.channels = channels
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        
        case channels
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(duration, forKey: .duration)
        
        try container.encode(channels, forKey: .channels)
    }
}

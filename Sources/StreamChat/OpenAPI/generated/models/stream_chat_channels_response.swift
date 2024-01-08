//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelsResponse: Codable, Hashable {
    public var channels: [StreamChatChannelStateResponseFields]
    
    public var duration: String
    
    public init(channels: [StreamChatChannelStateResponseFields], duration: String) {
        self.channels = channels
        
        self.duration = duration
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channels
        
        case duration
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(channels, forKey: .channels)
        
        try container.encode(duration, forKey: .duration)
    }
}

//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatMuteChannelResponse: Codable, Hashable {
    public var duration: String
    
    public var ownUser: StreamChatOwnUser?
    
    public var channelMute: StreamChatChannelMute?
    
    public var channelMutes: [StreamChatChannelMute?]?
    
    public init(duration: String, ownUser: StreamChatOwnUser?, channelMute: StreamChatChannelMute?, channelMutes: [StreamChatChannelMute?]?) {
        self.duration = duration
        
        self.ownUser = ownUser
        
        self.channelMute = channelMute
        
        self.channelMutes = channelMutes
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        
        case ownUser = "own_user"
        
        case channelMute = "channel_mute"
        
        case channelMutes = "channel_mutes"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(duration, forKey: .duration)
        
        try container.encode(ownUser, forKey: .ownUser)
        
        try container.encode(channelMute, forKey: .channelMute)
        
        try container.encode(channelMutes, forKey: .channelMutes)
    }
}

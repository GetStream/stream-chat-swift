//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatMuteChannelResponse: Codable, Hashable {
    public var ownUser: StreamChatOwnUser?
    
    public var channelMute: StreamChatChannelMute?
    
    public var channelMutes: [StreamChatChannelMute?]?
    
    public var duration: String
    
    public init(ownUser: StreamChatOwnUser?, channelMute: StreamChatChannelMute?, channelMutes: [StreamChatChannelMute?]?, duration: String) {
        self.ownUser = ownUser
        
        self.channelMute = channelMute
        
        self.channelMutes = channelMutes
        
        self.duration = duration
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case ownUser = "own_user"
        
        case channelMute = "channel_mute"
        
        case channelMutes = "channel_mutes"
        
        case duration
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(ownUser, forKey: .ownUser)
        
        try container.encode(channelMute, forKey: .channelMute)
        
        try container.encode(channelMutes, forKey: .channelMutes)
        
        try container.encode(duration, forKey: .duration)
    }
}

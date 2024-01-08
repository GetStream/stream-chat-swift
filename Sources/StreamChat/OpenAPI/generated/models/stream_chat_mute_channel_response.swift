//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatMuteChannelResponse: Codable, Hashable {
    public var channelMutes: [StreamChatChannelMute?]?
    
    public var duration: String
    
    public var ownUser: StreamChatOwnUser?
    
    public var channelMute: StreamChatChannelMute?
    
    public init(channelMutes: [StreamChatChannelMute?]?, duration: String, ownUser: StreamChatOwnUser?, channelMute: StreamChatChannelMute?) {
        self.channelMutes = channelMutes
        
        self.duration = duration
        
        self.ownUser = ownUser
        
        self.channelMute = channelMute
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channelMutes = "channel_mutes"
        
        case duration
        
        case ownUser = "own_user"
        
        case channelMute = "channel_mute"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(channelMutes, forKey: .channelMutes)
        
        try container.encode(duration, forKey: .duration)
        
        try container.encode(ownUser, forKey: .ownUser)
        
        try container.encode(channelMute, forKey: .channelMute)
    }
}

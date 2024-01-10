//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatMuteChannelResponse: Codable, Hashable {
    public var channelMute: StreamChatChannelMute?
    
    public var channelMutes: [StreamChatChannelMute?]?
    
    public var duration: String
    
    public var ownUser: StreamChatOwnUser?
    
    public init(channelMute: StreamChatChannelMute?, channelMutes: [StreamChatChannelMute?]?, duration: String, ownUser: StreamChatOwnUser?) {
        self.channelMute = channelMute
        
        self.channelMutes = channelMutes
        
        self.duration = duration
        
        self.ownUser = ownUser
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channelMute = "channel_mute"
        
        case channelMutes = "channel_mutes"
        
        case duration
        
        case ownUser = "own_user"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(channelMute, forKey: .channelMute)
        
        try container.encode(channelMutes, forKey: .channelMutes)
        
        try container.encode(duration, forKey: .duration)
        
        try container.encode(ownUser, forKey: .ownUser)
    }
}

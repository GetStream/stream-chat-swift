//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct MuteChannelResponse: Codable, Hashable {
    public var duration: String
    public var channelMutes: [ChannelMute?]? = nil
    public var channelMute: ChannelMute? = nil
    public var ownUser: OwnUser? = nil

    public init(duration: String, channelMutes: [ChannelMute?]? = nil, channelMute: ChannelMute? = nil, ownUser: OwnUser? = nil) {
        self.duration = duration
        self.channelMutes = channelMutes
        self.channelMute = channelMute
        self.ownUser = ownUser
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case channelMutes = "channel_mutes"
        case channelMute = "channel_mute"
        case ownUser = "own_user"
    }
}

//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class MuteChannelResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var channelMute: ChannelMute?
    /// Object with mutes (if multiple channels were muted)
    var channelMutes: [ChannelMute]?
    var duration: String
    var ownUser: OwnUserResponse?

    init(channelMute: ChannelMute? = nil, channelMutes: [ChannelMute]? = nil, duration: String, ownUser: OwnUserResponse? = nil) {
        self.channelMute = channelMute
        self.channelMutes = channelMutes
        self.duration = duration
        self.ownUser = ownUser
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channelMute = "channel_mute"
        case channelMutes = "channel_mutes"
        case duration
        case ownUser = "own_user"
    }

    static func == (lhs: MuteChannelResponse, rhs: MuteChannelResponse) -> Bool {
        lhs.channelMute == rhs.channelMute &&
            lhs.channelMutes == rhs.channelMutes &&
            lhs.duration == rhs.duration &&
            lhs.ownUser == rhs.ownUser
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(channelMute)
        hasher.combine(channelMutes)
        hasher.combine(duration)
        hasher.combine(ownUser)
    }
}

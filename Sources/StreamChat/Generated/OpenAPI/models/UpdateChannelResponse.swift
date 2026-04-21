//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UpdateChannelResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var channel: ChannelResponse?
    /// Duration of the request in milliseconds
    var duration: String
    /// List of channel members
    var members: [ChannelMemberResponse]
    var message: MessageResponse?

    init(channel: ChannelResponse? = nil, duration: String, members: [ChannelMemberResponse], message: MessageResponse? = nil) {
        self.channel = channel
        self.duration = duration
        self.members = members
        self.message = message
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channel
        case duration
        case members
        case message
    }

    static func == (lhs: UpdateChannelResponse, rhs: UpdateChannelResponse) -> Bool {
        lhs.channel == rhs.channel &&
            lhs.duration == rhs.duration &&
            lhs.members == rhs.members &&
            lhs.message == rhs.message
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(channel)
        hasher.combine(duration)
        hasher.combine(members)
        hasher.combine(message)
    }
}

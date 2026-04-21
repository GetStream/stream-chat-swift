//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UpdateChannelPartialResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var channel: ChannelResponse?
    /// Duration of the request in milliseconds
    var duration: String
    /// List of updated members
    var members: [ChannelMemberResponse]

    init(channel: ChannelResponse? = nil, duration: String, members: [ChannelMemberResponse]) {
        self.channel = channel
        self.duration = duration
        self.members = members
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channel
        case duration
        case members
    }

    static func == (lhs: UpdateChannelPartialResponse, rhs: UpdateChannelPartialResponse) -> Bool {
        lhs.channel == rhs.channel &&
            lhs.duration == rhs.duration &&
            lhs.members == rhs.members
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(channel)
        hasher.combine(duration)
        hasher.combine(members)
    }
}

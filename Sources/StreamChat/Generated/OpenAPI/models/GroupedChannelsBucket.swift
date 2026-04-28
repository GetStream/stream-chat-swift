//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class GroupedChannelsBucket: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Channels returned for this bucket
    var channels: [ChannelStateResponseFields]
    /// Unread channels currently classified into this bucket
    var unreadChannels: Int?

    init(channels: [ChannelStateResponseFields], unreadChannels: Int? = nil) {
        self.channels = channels
        self.unreadChannels = unreadChannels
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channels
        case unreadChannels = "unread_channels"
    }

    static func == (lhs: GroupedChannelsBucket, rhs: GroupedChannelsBucket) -> Bool {
        lhs.channels == rhs.channels &&
            lhs.unreadChannels == rhs.unreadChannels
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(channels)
        hasher.combine(unreadChannels)
    }
}

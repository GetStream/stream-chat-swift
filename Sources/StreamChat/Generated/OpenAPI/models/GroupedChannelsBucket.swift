//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class GroupedChannelsBucket: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Channels returned for this bucket
    var channels: [ChannelStateResponseFields]
    /// Cursor for the next page of this group
    var next: String?
    /// Cursor for the previous page of this group
    var prev: String?
    /// Unread channels currently classified into this bucket
    var unreadChannels: Int?

    init(channels: [ChannelStateResponseFields], next: String? = nil, prev: String? = nil, unreadChannels: Int? = nil) {
        self.channels = channels
        self.next = next
        self.prev = prev
        self.unreadChannels = unreadChannels
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channels
        case next
        case prev
        case unreadChannels = "unread_channels"
    }

    static func == (lhs: GroupedChannelsBucket, rhs: GroupedChannelsBucket) -> Bool {
        lhs.channels == rhs.channels &&
            lhs.next == rhs.next &&
            lhs.prev == rhs.prev &&
            lhs.unreadChannels == rhs.unreadChannels
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(channels)
        hasher.combine(next)
        hasher.combine(prev)
        hasher.combine(unreadChannels)
    }
}

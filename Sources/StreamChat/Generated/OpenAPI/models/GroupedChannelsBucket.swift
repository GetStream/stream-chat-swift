//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class GroupedChannelsBucket: Sendable, Decodable {
    /// Channels returned for this bucket
    let channels: [ChannelStateResponseFields]
    /// Cursor for the next page of this group
    let next: String?
    /// Cursor for the previous page of this group
    let prev: String?
    /// Unread channels currently classified into this bucket
    let unreadChannels: Int?

    init(
        channels: [ChannelStateResponseFields],
        next: String? = nil,
        prev: String? = nil,
        unreadChannels: Int? = nil
    ) {
        self.channels = channels
        self.next = next
        self.prev = prev
        self.unreadChannels = unreadChannels
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.channels = try container.decodeArrayIgnoringFailures(
            [ChannelStateResponseFields].self,
            forKey: .channels
        )
        self.next = try container.decodeIfPresent(String.self, forKey: .next)
        self.prev = try container.decodeIfPresent(String.self, forKey: .prev)
        self.unreadChannels = try container.decodeIfPresent(Int.self, forKey: .unreadChannels)
    }
}

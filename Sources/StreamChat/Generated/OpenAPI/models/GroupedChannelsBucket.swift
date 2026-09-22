//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class GroupedChannelsBucket: Sendable, Decodable {
    /// Channels returned for this bucket
    let channels: [ChannelStateResponse]
    /// Cursor for the next page of this group
    let next: String?
    /// Cursor for the previous page of this group
    let prev: String?
    /// Unread channels currently classified into this bucket
    let unreadChannels: Int?

    init(
        channels: [ChannelStateResponse],
        next: String? = nil,
        prev: String? = nil,
        unreadChannels: Int? = nil
    ) {
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
}

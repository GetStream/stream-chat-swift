//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The unread information of a channel.
public final class UnreadChannel: Sendable, Decodable {
    /// The channel CID (type:id).
    public let channelId: ChannelId
    /// The date which the current user last read the channel.
    public let lastRead: Date?
    /// The number of unread messages inside the channel.
    public let unreadCount: Int

    init(channelId: ChannelId, lastRead: Date? = nil, unreadCount: Int) {
        self.channelId = channelId
        self.lastRead = lastRead
        self.unreadCount = unreadCount
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channelId = "channel_id"
        case lastRead = "last_read"
        case unreadCount = "unread_count"
    }
}

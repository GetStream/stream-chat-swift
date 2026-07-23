//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class UnreadChannel: Sendable, Codable, JSONEncodable {
    public let channelId: ChannelId
    public let lastRead: Date?
    public let unreadCount: Int

    init(
        channelId: ChannelId,
        lastRead: Date,
        unreadCount: Int
    ) {
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

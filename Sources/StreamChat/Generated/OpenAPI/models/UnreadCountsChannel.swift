//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UnreadCountsChannel: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var channelId: String
    var lastRead: Date
    var unreadCount: Int

    init(channelId: String, lastRead: Date, unreadCount: Int) {
        self.channelId = channelId
        self.lastRead = lastRead
        self.unreadCount = unreadCount
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channelId = "channel_id"
        case lastRead = "last_read"
        case unreadCount = "unread_count"
    }

    static func == (lhs: UnreadCountsChannel, rhs: UnreadCountsChannel) -> Bool {
        lhs.channelId == rhs.channelId &&
            lhs.lastRead == rhs.lastRead &&
            lhs.unreadCount == rhs.unreadCount
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(channelId)
        hasher.combine(lastRead)
        hasher.combine(unreadCount)
    }
}

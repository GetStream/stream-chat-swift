//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UnreadCountsThread: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var lastRead: Date
    var lastReadMessageId: String
    var parentMessageId: String
    var unreadCount: Int

    init(lastRead: Date, lastReadMessageId: String, parentMessageId: String, unreadCount: Int) {
        self.lastRead = lastRead
        self.lastReadMessageId = lastReadMessageId
        self.parentMessageId = parentMessageId
        self.unreadCount = unreadCount
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case lastRead = "last_read"
        case lastReadMessageId = "last_read_message_id"
        case parentMessageId = "parent_message_id"
        case unreadCount = "unread_count"
    }

    static func == (lhs: UnreadCountsThread, rhs: UnreadCountsThread) -> Bool {
        lhs.lastRead == rhs.lastRead &&
            lhs.lastReadMessageId == rhs.lastReadMessageId &&
            lhs.parentMessageId == rhs.parentMessageId &&
            lhs.unreadCount == rhs.unreadCount
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(lastRead)
        hasher.combine(lastReadMessageId)
        hasher.combine(parentMessageId)
        hasher.combine(unreadCount)
    }
}

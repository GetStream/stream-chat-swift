//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class UnreadThread: Sendable, Codable, JSONEncodable {
    public let lastRead: Date?
    public let lastReadMessageId: String?
    public let parentMessageId: String
    public let unreadCount: Int

    init(
        lastRead: Date? = nil,
        lastReadMessageId: String? = nil,
        parentMessageId: String,
        unreadCount: Int
    ) {
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
}

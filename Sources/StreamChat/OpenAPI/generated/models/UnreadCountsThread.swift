//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct UnreadCountsThread: Codable, Hashable {
    public var lastRead: Date
    public var lastReadMessageId: String
    public var parentMessageId: String
    public var unreadCount: Int

    public init(lastRead: Date, lastReadMessageId: String, parentMessageId: String, unreadCount: Int) {
        self.lastRead = lastRead
        self.lastReadMessageId = lastReadMessageId
        self.parentMessageId = parentMessageId
        self.unreadCount = unreadCount
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case lastRead = "last_read"
        case lastReadMessageId = "last_read_message_id"
        case parentMessageId = "parent_message_id"
        case unreadCount = "unread_count"
    }
}

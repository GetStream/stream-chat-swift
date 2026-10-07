//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The unread information of a thread.
public final class UnreadThread: Sendable, Decodable {
    /// The date which the current user last read the thread.
    public let lastRead: Date?
    /// The id of the last reply which the current user read in the thread.
    public let lastReadMessageId: String?
    /// The message id of the root of the thread.
    public let parentMessageId: String
    /// The number of unread replies inside the thread.
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

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.lastRead = try container.decodeIfPresent(Date.self, forKey: .lastRead)
        self.lastReadMessageId = try container.decodeIfPresent(
            String.self,
            forKey: .lastReadMessageId
        )
        self.parentMessageId = try container.decode(String.self, forKey: .parentMessageId)
        self.unreadCount = try container.decode(Int.self, forKey: .unreadCount)
    }
}

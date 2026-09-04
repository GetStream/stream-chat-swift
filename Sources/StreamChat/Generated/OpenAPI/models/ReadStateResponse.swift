//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ReadStateResponse: Sendable, Decodable {
    let lastDeliveredAt: Date?
    let lastDeliveredMessageId: String?
    let lastRead: Date
    let lastReadMessageId: String?
    let unreadMessages: Int
    /// User response object
    let user: UserPayload

    init(
        lastDeliveredAt: Date? = nil,
        lastDeliveredMessageId: String? = nil,
        lastRead: Date,
        lastReadMessageId: String? = nil,
        unreadMessages: Int,
        user: UserPayload
    ) {
        self.lastDeliveredAt = lastDeliveredAt
        self.lastDeliveredMessageId = lastDeliveredMessageId
        self.lastRead = lastRead
        self.lastReadMessageId = lastReadMessageId
        self.unreadMessages = unreadMessages
        self.user = user
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case lastDeliveredAt = "last_delivered_at"
        case lastDeliveredMessageId = "last_delivered_message_id"
        case lastRead = "last_read"
        case lastReadMessageId = "last_read_message_id"
        case unreadMessages = "unread_messages"
        case user
    }
}

//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ReadStateResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var lastDeliveredAt: Date?
    var lastDeliveredMessageId: String?
    var lastRead: Date
    var lastReadMessageId: String?
    var unreadMessages: Int
    var user: UserResponse

    init(lastDeliveredAt: Date? = nil, lastDeliveredMessageId: String? = nil, lastRead: Date, lastReadMessageId: String? = nil, unreadMessages: Int, user: UserResponse) {
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

    static func == (lhs: ReadStateResponse, rhs: ReadStateResponse) -> Bool {
        lhs.lastDeliveredAt == rhs.lastDeliveredAt &&
            lhs.lastDeliveredMessageId == rhs.lastDeliveredMessageId &&
            lhs.lastRead == rhs.lastRead &&
            lhs.lastReadMessageId == rhs.lastReadMessageId &&
            lhs.unreadMessages == rhs.unreadMessages &&
            lhs.user == rhs.user
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(lastDeliveredAt)
        hasher.combine(lastDeliveredMessageId)
        hasher.combine(lastRead)
        hasher.combine(lastReadMessageId)
        hasher.combine(unreadMessages)
        hasher.combine(user)
    }
}

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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.lastDeliveredAt = try container.decodeIfPresent(Date.self, forKey: .lastDeliveredAt)
        self.lastDeliveredMessageId = try container.decodeIfPresent(
            String.self,
            forKey: .lastDeliveredMessageId
        )
        self.lastRead = try container.decode(Date.self, forKey: .lastRead)
        self.lastReadMessageId = try container.decodeIfPresent(
            String.self,
            forKey: .lastReadMessageId
        )
        self.unreadMessages = try container.decode(Int.self, forKey: .unreadMessages)
        self.user = try container.decode(UserPayload.self, forKey: .user)
    }
}

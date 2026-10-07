//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Emitted when a channel/thread is marked as unread.
final class NotificationMarkUnreadEventDTO: Sendable, Event, Decodable {
    /// Represents channel in chat
    let channel: ChannelDetailPayload?
    /// The CID of the channel which was marked as unread
    let cid: ChannelId
    /// Date/time of creation
    let createdAt: Date
    /// The ID of the first unread message
    let firstUnreadMessageId: String?
    let groupedUnreadChannels: [String: Int]?
    /// The time when the channel/thread was marked as unread
    let lastReadAt: Date?
    /// The ID of the last read message
    let lastReadMessageId: String?
    /// The total number of unread messages
    let totalUnreadCount: Int?
    /// The type of event: "notification.mark_unread" in this case
    let type: String
    /// The number of channels with unread messages
    let unreadChannels: Int?
    /// The number of unread messages in the channel/thread after first_unread_message_id
    let unreadMessages: Int?
    /// The number of unread threads
    let unreadThreads: Int?
    let user: UserPayload?

    init(
        channel: ChannelDetailPayload? = nil,
        cid: ChannelId,
        createdAt: Date,
        firstUnreadMessageId: String? = nil,
        groupedUnreadChannels: [String: Int]? = nil,
        lastReadAt: Date? = nil,
        lastReadMessageId: String? = nil,
        totalUnreadCount: Int? = nil,
        type: String = "notification.mark_unread",
        unreadChannels: Int? = nil,
        unreadMessages: Int? = nil,
        unreadThreads: Int? = nil,
        user: UserPayload? = nil
    ) {
        self.channel = channel
        self.cid = cid
        self.createdAt = createdAt
        self.firstUnreadMessageId = firstUnreadMessageId
        self.groupedUnreadChannels = groupedUnreadChannels
        self.lastReadAt = lastReadAt
        self.lastReadMessageId = lastReadMessageId
        self.totalUnreadCount = totalUnreadCount
        self.type = type
        self.unreadChannels = unreadChannels
        self.unreadMessages = unreadMessages
        self.unreadThreads = unreadThreads
        self.user = user
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.channel = try container.decodeIfPresent(ChannelDetailPayload.self, forKey: .channel)
        self.cid = try container.decode(ChannelId.self, forKey: .cid)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.firstUnreadMessageId = try container.decodeIfPresent(
            String.self,
            forKey: .firstUnreadMessageId
        )
        self.groupedUnreadChannels = try container.decodeIfPresent(
            [String: Int].self,
            forKey: .groupedUnreadChannels
        )
        self.lastReadAt = try container.decodeIfPresent(Date.self, forKey: .lastReadAt)
        self.lastReadMessageId = try container.decodeIfPresent(
            String.self,
            forKey: .lastReadMessageId
        )
        self.totalUnreadCount = try container.decodeIfPresent(Int.self, forKey: .totalUnreadCount)
        self.type = try container.decode(String.self, forKey: .type)
        self.unreadChannels = try container.decodeIfPresent(Int.self, forKey: .unreadChannels)
        self.unreadMessages = try container.decodeIfPresent(Int.self, forKey: .unreadMessages)
        self.unreadThreads = try container.decodeIfPresent(Int.self, forKey: .unreadThreads)
        self.user = try container.decodeIfPresent(UserPayload.self, forKey: .user)
    }
}

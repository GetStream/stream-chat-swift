//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Emitted when a channel/thread is marked as read.
final class NotificationMarkReadEventDTO: Sendable, Event, Decodable {
    /// Represents channel in chat
    let channel: ChannelDetailPayload?
    /// The CID of the channel which was marked as read
    let cid: ChannelId?
    /// Date/time of creation
    let createdAt: Date
    let groupedUnreadChannels: [String: Int]?
    /// The ID of the last read message
    let lastReadMessageId: String?
    let thread: ThreadResponse?
    /// The total number of unread messages
    let totalUnreadCount: Int
    /// The type of event: "notification.mark_read" in this case
    let type: String
    /// The number of channels with unread messages
    let unreadChannels: Int
    /// The number of unread threads
    let unreadThreads: Int?
    let user: UserPayload?

    init(
        channel: ChannelDetailPayload? = nil,
        cid: ChannelId? = nil,
        createdAt: Date,
        groupedUnreadChannels: [String: Int]? = nil,
        lastReadMessageId: String? = nil,
        thread: ThreadResponse? = nil,
        totalUnreadCount: Int,
        type: String = "notification.mark_read",
        unreadChannels: Int,
        unreadThreads: Int? = nil,
        user: UserPayload? = nil
    ) {
        self.channel = channel
        self.cid = cid
        self.createdAt = createdAt
        self.groupedUnreadChannels = groupedUnreadChannels
        self.lastReadMessageId = lastReadMessageId
        self.thread = thread
        self.totalUnreadCount = totalUnreadCount
        self.type = type
        self.unreadChannels = unreadChannels
        self.unreadThreads = unreadThreads
        self.user = user
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.channel = try container.decodeIfPresent(ChannelDetailPayload.self, forKey: .channel)
        self.cid = try container.decodeIfPresent(ChannelId.self, forKey: .cid)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.groupedUnreadChannels = try container.decodeIfPresent(
            [String: Int].self,
            forKey: .groupedUnreadChannels
        )
        self.lastReadMessageId = try container.decodeIfPresent(
            String.self,
            forKey: .lastReadMessageId
        )
        self.thread = try container.decodeIfPresent(ThreadResponse.self, forKey: .thread)
        self.totalUnreadCount = try container.decode(Int.self, forKey: .totalUnreadCount)
        self.type = try container.decode(String.self, forKey: .type)
        self.unreadChannels = try container.decode(Int.self, forKey: .unreadChannels)
        self.unreadThreads = try container.decodeIfPresent(Int.self, forKey: .unreadThreads)
        self.user = try container.decodeIfPresent(UserPayload.self, forKey: .user)
    }
}
